import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from '../config/database';
import { getRedisClient } from '../config/redis';
import { EncryptionUtils } from '../utils/encryption';

export class AuthService {
    private static get JWT_SECRET(): string {
        const secret = process.env.JWT_SECRET;
        if (!secret) {
            throw new Error('FATAL: JWT_SECRET environment variable is missing.');
        }
        return secret;
    }
    private static readonly JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';

    private static get JWT_REFRESH_SECRET(): string {
        const secret = process.env.JWT_REFRESH_SECRET;
        if (!secret) {
            throw new Error('FATAL: JWT_REFRESH_SECRET environment variable is missing.');
        }
        return secret;
    }
    private static readonly JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

    private static readonly googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

    static async hashPassword(password: string): Promise<string> {
        return bcrypt.hash(password, 10);
    }

    static async comparePasswords(password: string, hash: string): Promise<boolean> {
        return bcrypt.compare(password, hash);
    }

    static generateToken(userId: string): string {
        return jwt.sign({ sub: userId }, this.JWT_SECRET, {
            expiresIn: this.JWT_EXPIRES_IN as any,
        });
    }

    static generateTokens(userId: string): { accessToken: string; refreshToken: string } {
        const accessToken = jwt.sign({ sub: userId }, this.JWT_SECRET, {
            expiresIn: this.JWT_EXPIRES_IN as any,
        });

        const refreshToken = jwt.sign({ sub: userId }, this.JWT_REFRESH_SECRET, {
            expiresIn: this.JWT_REFRESH_EXPIRES_IN as any,
        });

        return { accessToken, refreshToken };
    }

    static verifyRefreshToken(token: string): any {
        try {
            return jwt.verify(token, this.JWT_REFRESH_SECRET);
        } catch (error) {
            return null;
        }
    }

    static async verifyGoogleToken(idToken: string) {
        console.log('AuthService: Verifying Google Token...');

        const timeout = new Promise<never>((_, reject) =>
            setTimeout(() => reject(new Error('Google token verification timed out after 8s')), 8000)
        );

        try {
            const ticket = await Promise.race([
                this.googleClient.verifyIdToken({
                    idToken,
                    audience: process.env.GOOGLE_CLIENT_ID,
                }),
                timeout,
            ]);
            console.log('AuthService: Token verified successfully.');
            return ticket.getPayload();
        } catch (error: any) {
            console.error('Google token verification failed:', error?.message ?? error);
            return null;
        }
    }

    static async findUserByEmail(email: string) {
        return prisma.user.findUnique({
            where: { email },
        });
    }

    static async findUserById(id: string) {
        return prisma.user.findUnique({
            where: { id },
            include: {
                profile: true,
            },
        });
    }

    static toSafeUser(user: any) {
        if (!user) return null;
        return {
            id: user.id,
            email: user.email,
            fullName: user.fullName,
            role: user.role,
            createdAt: user.createdAt.toISOString(),
            isEmailVerified: user.emailVerified, // Get actual status from database
            acceptedTermsVersion: user.acceptedTermsVersion,
            acceptedTermsAt: user.acceptedTermsAt?.toISOString(),
            profile: user.profile ? {
                id: user.profile.id,
                bio: EncryptionUtils.decrypt(user.profile.bio || ''),
                avatar: user.profile.avatar,
                mobile: EncryptionUtils.decrypt(user.profile.mobile || ''),
                mailingAddress: EncryptionUtils.decrypt(user.profile.mailingAddress || ''),
                metadata: user.profile.metadata,
                points: user.profile.points,
                totalPoints: user.profile.totalPoints,
            } : null,
        };
    }

    static async revokeToken(token: string): Promise<void> {
        try {
            const decoded = jwt.decode(token) as any;
            if (!decoded || !decoded.exp) return;

            const now = Math.floor(Date.now() / 1000);
            const ttl = decoded.exp - now;

            if (ttl > 0) {
                const redis = getRedisClient();
                await redis.set(`revoked_token:${token}`, 'true', 'EX', ttl);
            }
        } catch (error) {
            console.error('Error revoking token:', error);
        }
    }

    static async isTokenRevoked(token: string): Promise<boolean> {
        try {
            const redis = getRedisClient();
            const result = await redis.get(`revoked_token:${token}`);
            return result === 'true';
        } catch (error) {
            console.error('Error checking token revocation:', error);
            return false;
        }
    }

    /**
     * Verifies the Cloudflare Turnstile CAPTCHA token.
     * @param token The token received from the client.
     * @returns boolean indicating if the token is valid.
     */
    static async verifyCaptcha(token: string): Promise<boolean> {
        if (!token) return false;

        const secretKey = process.env.TURNSTILE_SECRET_KEY;
        if (!secretKey) {
            console.warn('AuthService: TURNSTILE_SECRET_KEY is not set. CAPTCHA verification bypassed.');
            return true; // Bypass if not configured (useful for dev/local)
        }

        try {
            const axios = (await import('axios')).default;
            const response = await axios.post(
                'https://challenges.cloudflare.com/turnstile/v0/siteverify',
                {
                    secret: secretKey,
                    response: token,
                }
            );

            const { success } = response.data as any;
            return success === true;
        } catch (error: any) {
            console.error('AuthService: Turnstile verification error:', error?.message ?? error);
            return false;
        }
    }
}

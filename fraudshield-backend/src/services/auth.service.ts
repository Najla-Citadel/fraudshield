import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from '../config/database';

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
            isEmailVerified: true, // Mocked for now to match UserModel
            profile: user.profile ? {
                id: user.profile.id,
                bio: user.profile.bio,
                avatar: user.profile.avatar,
                metadata: user.profile.metadata,
                points: user.profile.points,
                totalPoints: user.profile.totalPoints,
            } : null,
        };
    }
}

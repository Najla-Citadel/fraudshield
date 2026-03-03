import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from '../config/database';
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
<<<<<<< HEAD
=======

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
>>>>>>> dev-ui2
}

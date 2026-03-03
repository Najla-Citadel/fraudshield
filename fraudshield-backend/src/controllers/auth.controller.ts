import { Request, Response, NextFunction } from 'express';
import passport from '../config/passport';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database';
import { AuthService } from '../services/auth.service';
import { EmailService } from '../services/email.service';
import { AlertService } from '../services/alert.service';
import { AlertCategory, AlertSeverity } from '@prisma/client';
import { EncryptionUtils } from '../utils/encryption';

/**
 * @openapi
 * tags:
 *   name: Auth
 *   description: User authentication and profile management
 */
export class AuthController {
    /**
     * @openapi
     * /api/v1/auth/signup:
     *   post:
     *     summary: Register a new user
     *     tags: [Auth]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required: [email, password]
     *             properties:
     *               email: { type: string, format: email }
     *               password: { type: string, format: password }
     *               fullName: { type: string }
     *     responses:
     *       201:
     *         description: User created successfully
     */
    static async signup(req: Request, res: Response, next: NextFunction) {
        try {
            const { email, password, fullName, captchaToken } = req.body;

            // 🛡️ CAPTCHA Verification
            const isCaptchaValid = await AuthService.verifyCaptcha(captchaToken);
            if (!isCaptchaValid) {
                return res.status(400).json({ message: 'Invalid CAPTCHA. Please try again.' });
            }

            // 🛡️ Email Deliverability Check
            const deliverability = await EmailService.validateDeliverability(email);
            if (!deliverability.valid) {
                return res.status(400).json({ message: deliverability.reason });
            }

            // Check if user exists
            const existingUser = await prisma.user.findUnique({ where: { email } });
            if (existingUser) {
                return res.status(400).json({ message: 'Email already in use' });
            }

            // Hash password
            const passwordHash = await AuthService.hashPassword(password);

            // Create user and profile
            const user = await prisma.user.create({
                data: {
                    email,
                    passwordHash,
                    fullName,
                    acceptedTermsVersion: 'v1.0',
                    acceptedTermsAt: new Date(),
                    profile: {
                        create: {
                            avatar: 'Felix',
                        },
                    },
                },
                include: {
                    profile: true,
                },
            });

            // Generate tokens
            const { accessToken, refreshToken } = AuthService.generateTokens(user.id);

            // Store refresh token
            await prisma.user.update({
                where: { id: user.id },
                data: { refreshToken },
            });

            // Generate OTP and store in Redis for email verification
            const otp = await EmailService.generateEmailVerificationOtp(email);

            // In local development, we return the OTP for easy testing. 
            // In production, NEVER return the OTP in the HTTP response.
            if (process.env.NODE_ENV === 'development') {
                return res.status(201).json({
                    user: AuthService.toSafeUser(user),
                    token: accessToken,
                    refreshToken,
                    message: 'Account created. Please verify your email.',
                    dev_otp: otp
                });
            }

            res.status(201).json({
                user: AuthService.toSafeUser(user),
                token: accessToken,
                refreshToken,
                message: 'Account created. Please verify your email.'
            });
        } catch (error) {
            next(error);
        }
    }

    static async verifyEmail(req: Request, res: Response, next: NextFunction) {
        try {
            const { email, otp } = req.body;

            if (!email || !otp) {
                return res.status(400).json({ error: 'Email and OTP are required' });
            }

            // Verify OTP with Redis
            const isValid = await EmailService.verifyEmailOtp(email, otp);

            if (!isValid) {
                return res.status(400).json({ error: 'Invalid or expired verification code' });
            }

            // Update User in DB
            await prisma.user.update({
                where: { email },
                data: { emailVerified: true },
            });

            res.json({ message: 'Email successfully verified' });
        } catch (error) {
            next(error);
        }
    }

    static async requestEmailVerification(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any)?.id;
            const user = await prisma.user.findUnique({ where: { id: userId } });

            if (!user) {
                return res.status(404).json({ error: 'User not found' });
            }

            if (user.emailVerified) {
                return res.status(400).json({ message: 'Email already verified' });
            }

            // Generate OTP and store in Redis for email verification
            const otp = await EmailService.generateEmailVerificationOtp(user.email);

            // In local development, we return the OTP for easy testing. 
            // In production, NEVER return the OTP in the HTTP response.
            if (process.env.NODE_ENV === 'development') {
                return res.status(200).json({
                    message: 'Verification code sent to your email.',
                    dev_otp: otp
                });
            }

            res.status(200).json({
                message: 'Verification code sent to your email.'
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/auth/login:
     *   post:
     *     summary: Authenticate user and get tokens
     *     tags: [Auth]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required: [email, password]
     *             properties:
     *               email: { type: string, format: email }
     *               password: { type: string, format: password }
     *     responses:
     *       200:
     *         description: Login successful
     */
    static async login(req: Request, res: Response, next: NextFunction) {
        passport.authenticate('local', { session: false }, async (err: any, user: any, info: any) => {
            if (err) return next(err);
            if (!user) {
                return res.status(401).json({ message: info?.message || 'Login failed' });
            }

            // Fetch user with profile for a complete response
            const fullUser = await AuthService.findUserById(user.id);
            const { accessToken, refreshToken } = AuthService.generateTokens(user.id);

            // Store refresh token
            await prisma.user.update({
                where: { id: user.id },
                data: { refreshToken },
            });

            // FOR DEMO: Generate a "Welcome" alert and a "Security Scan" alert
            await AlertService.createAlert({
                userId: user.id,
                category: AlertCategory.COMMUNITY,
                severity: AlertSeverity.LOW,
                title: 'Welcome to FraudShield',
                message: 'Your account is now protected. We are monitoring for threats in your area.',
            });

            await AlertService.createAlert({
                userId: user.id,
                category: AlertCategory.SYSTEM_SCAN,
                severity: AlertSeverity.LOW,
                title: 'Initial System Scan Completed',
                message: '0 threats found. Your device security is up to date.',
            });

            res.json({
                user: AuthService.toSafeUser(fullUser),
                token: accessToken,
                refreshToken,
            });
        })(req, res, next);
    }

    /**
     * @openapi
     * /api/v1/auth/profile:
     *   get:
     *     summary: Get current user profile
     *     tags: [Auth]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Successfully retrieved profile
     */
    static async getProfile(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const fullUser = await AuthService.findUserById(userId);
            res.json(AuthService.toSafeUser(fullUser));
        } catch (error) {
            next(error);
        }
    }

    static async updateProfile(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { bio, avatar, fullName, metadata, mobile, mailingAddress } = req.body;

            if (fullName) {
                await prisma.user.update({
                    where: { id: userId },
                    data: { fullName },
                });
            }

            const profile = await prisma.profile.upsert({
                where: { userId },
                update: {
                    bio: bio ? EncryptionUtils.encrypt(bio) : undefined,
                    avatar,
                    mobile: mobile ? EncryptionUtils.encrypt(mobile) : undefined,
                    mailingAddress: mailingAddress ? EncryptionUtils.encrypt(mailingAddress) : undefined,
                    metadata: metadata || undefined,
                },
                create: {
                    userId,
                    bio: bio ? EncryptionUtils.encrypt(bio) : '',
                    avatar: avatar || 'Felix',
                    mobile: mobile ? EncryptionUtils.encrypt(mobile) : '',
                    mailingAddress: mailingAddress ? EncryptionUtils.encrypt(mailingAddress) : '',
                    metadata: metadata || {},
                },
            });

            res.json({
                ...profile,
                bio: EncryptionUtils.decrypt(profile.bio || ''),
                mobile: EncryptionUtils.decrypt(profile.mobile || ''),
                mailingAddress: EncryptionUtils.decrypt(profile.mailingAddress || ''),
            });
        } catch (error) {
            next(error);
        }
    }

    static async changePassword(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { currentPassword, newPassword } = req.body;

            // Fetch user to get current password hash
            const user = await prisma.user.findUnique({
                where: { id: userId },
            });

            if (!user) {
                res.status(404).json({ error: 'User not found' });
                return;
            }

            // Verify current password
            const isMatch = await AuthService.comparePasswords(currentPassword, user.passwordHash);
            if (!isMatch) {
                res.status(400).json({ error: 'Incorrect current password' });
                return;
            }

            const passwordHash = await AuthService.hashPassword(newPassword);

            await prisma.user.update({
                where: { id: userId },
                data: { passwordHash },
            });

            res.json({ message: 'Password updated successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async requestPasswordReset(req: Request, res: Response, next: NextFunction) {
        try {
            const { email } = req.body;

            if (!email) {
                return res.status(400).json({ error: 'Email is required' });
            }

            const user = await prisma.user.findUnique({ where: { email } });

            if (!user) {
                // Return success even if user not found to prevent email enumeration attacks
                return res.json({ message: 'If an account exists, a reset code has been sent.' });
            }

            // Generate OTP and store in Redis
            const otp = await EmailService.generatePasswordResetOtp(email);

            // In local development, we return the OTP for easy testing. 
            // In production, NEVER return the OTP in the HTTP response.
            if (process.env.NODE_ENV === 'development') {
                return res.json({
                    message: 'If an account exists, a reset code has been sent.',
                    dev_otp: otp
                });
            }

            res.json({ message: 'If an account exists, a reset code has been sent.' });
        } catch (error) {
            next(error);
        }
    }

    static async verifyAndResetPassword(req: Request, res: Response, next: NextFunction) {
        try {
            const { email, otp, newPassword } = req.body;

            if (!email || !otp || !newPassword) {
                return res.status(400).json({ error: 'Email, OTP, and new password are required' });
            }

            // 1. Verify OTP with Redis
            const isValid = await EmailService.verifyPasswordResetOtp(email, otp);

            if (!isValid) {
                return res.status(400).json({ error: 'Invalid or expired reset code' });
            }

            // 2. Hash new password
            const passwordHash = await AuthService.hashPassword(newPassword);

            // 3. Update User in DB
            await prisma.user.update({
                where: { email },
                data: { passwordHash },
            });

            res.json({ message: 'Password has been successfully reset. You can now log in.' });
        } catch (error) {
            next(error);
        }
    }

    static async refresh(req: Request, res: Response, next: NextFunction) {
        try {
            const { refreshToken } = req.body;

            if (!refreshToken) {
                return res.status(400).json({ message: 'Refresh token is required' });
            }

            const payload = AuthService.verifyRefreshToken(refreshToken);
            if (!payload) {
                return res.status(401).json({ message: 'Invalid or expired refresh token' });
            }

            const user = await prisma.user.findUnique({
                where: { id: payload.sub },
            });

            if (!user || user.refreshToken !== refreshToken) {
                return res.status(401).json({ message: 'Invalid refresh token' });
            }

            const tokens = AuthService.generateTokens(user.id);

            // Rotate refresh token
            await prisma.user.update({
                where: { id: user.id },
                data: { refreshToken: tokens.refreshToken },
            });

            res.json({
                token: tokens.accessToken,
                refreshToken: tokens.refreshToken,
            });
        } catch (error) {
            next(error);
        }
    }

    static async logout(req: Request, res: Response, next: NextFunction) {
        try {
            const authHeader = req.headers.authorization;
            if (authHeader && authHeader.startsWith('Bearer ')) {
                const token = authHeader.split(' ')[1];
                await AuthService.revokeToken(token);
            }

            const userId = (req.user as any)?.id;
            if (userId) {
                await prisma.user.update({
                    where: { id: userId },
                    data: { refreshToken: null },
                });
            }
            res.json({ message: 'Logged out successfully' });
        } catch (error) {
            next(error);
        }
    }

    static async googleLogin(req: Request, res: Response, next: NextFunction) {
        try {
            const { idToken } = req.body;
            if (!idToken) {
                return res.status(400).json({ message: 'Google ID Token is required' });
            }

            const payload = await AuthService.verifyGoogleToken(idToken);
            if (!payload) {
                return res.status(401).json({ message: 'Invalid Google token' });
            }

            const { email, name, picture, sub: googleId } = payload;
            if (!email) {
                return res.status(400).json({ message: 'Google account must have an email' });
            }

            // Find or create user
            let user = await prisma.user.findUnique({
                where: { email },
                include: { profile: true },
            });

            if (!user) {
                // Auto-register (random password since they'll use Google)
                const passwordHash = await AuthService.hashPassword(Math.random().toString(36).substring(2, 12));
                user = await prisma.user.create({
                    data: {
                        email,
                        fullName: name || 'Google User',
                        passwordHash,
                        emailVerified: true,
                        profile: {
                            create: {
                                avatar: 'Felix',
                                bio: 'Joined via Google',
                            },
                        },
                        acceptedTermsVersion: 'v1.0',
                        acceptedTermsAt: new Date(),
                    },
                    include: { profile: true },
                });
            } else if (!user.emailVerified || (!user.fullName && name)) {
                // Sync name from Google for existing users if missing and mark email as verified
                user = await prisma.user.update({
                    where: { id: user.id },
                    data: {
                        fullName: name || user.fullName,
                        emailVerified: true
                    },
                    include: { profile: true },
                });
            }

            // Generate tokens
            const { accessToken, refreshToken } = AuthService.generateTokens(user.id);

            // Store refresh token
            await prisma.user.update({
                where: { id: user.id },
                data: { refreshToken },
            });

            res.json({
                user: AuthService.toSafeUser(user),
                token: accessToken,
                refreshToken,
            });
        } catch (error) {
            next(error);
        }
    }

    static async acceptTerms(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { version } = req.body;

            if (!version) {
                return res.status(400).json({ error: 'Terms version is required' });
            }

            const user = await prisma.user.update({
                where: { id: userId },
                data: {
                    acceptedTermsVersion: version,
                    acceptedTermsAt: new Date(),
                },
                include: { profile: true },
            });

            res.json({
                message: 'Terms and Privacy Policy accepted successfully',
                user: AuthService.toSafeUser(user),
            });
        } catch (error) {
            next(error);
        }
    }
}

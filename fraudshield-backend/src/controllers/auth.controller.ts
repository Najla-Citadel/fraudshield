import { Request, Response, NextFunction } from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database';
import { AuthService } from '../services/auth.service';

export class AuthController {
    static async signup(req: Request, res: Response, next: NextFunction) {
        try {
            const { email, password, fullName } = req.body;
            // Basic validation skipped (handled by middleware)

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

            // Generate token
            const token = AuthService.generateToken(user.id);

            res.status(201).json({
                user: AuthService.toSafeUser(user),
                token,
            });
        } catch (error) {
            next(error);
        }
    }

    static async login(req: Request, res: Response, next: NextFunction) {
        passport.authenticate('local', { session: false }, async (err: any, user: any, info: any) => {
            if (err) return next(err);
            if (!user) {
                return res.status(401).json({ message: info?.message || 'Login failed' });
            }

            // Fetch user with profile for a complete response
            const fullUser = await AuthService.findUserById(user.id);
            const token = AuthService.generateToken(user.id);

            res.json({
                user: AuthService.toSafeUser(fullUser),
                token,
            });
        })(req, res, next);
    }

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
            const { bio, avatar, fullName, metadata } = req.body;

            if (fullName) {
                await prisma.user.update({
                    where: { id: userId },
                    data: { fullName },
                });
            }

            const profile = await prisma.profile.upsert({
                where: { userId },
                update: {
                    bio,
                    avatar,
                    metadata: metadata || undefined,
                },
                create: {
                    userId,
                    bio,
                    avatar,
                    metadata: metadata || {},
                },
            });

            res.json(profile);
        } catch (error) {
            next(error);
        }
    }

    static async changePassword(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { newPassword } = req.body;

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

    static async logout(req: Request, res: Response, next: NextFunction) {
        // For JWT, logout is usually handled client-side by deleting the token.
        // Optionally, you could blacklist tokens in Redis here.
        res.json({ message: 'Logged out successfully' });
    }
}

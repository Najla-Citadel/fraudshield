import { Request, Response, NextFunction } from 'express';
<<<<<<< HEAD
import passport from 'passport';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
    passport.authenticate('jwt', { session: false }, (err: any, user: any, info: any) => {
=======
import passport from '../config/passport';
import { AuthService } from '../services/auth.service';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
    passport.authenticate('jwt', { session: false }, async (err: any, user: any, info: any) => {
>>>>>>> dev-ui2
        if (err) return next(err);
        if (!user) {
            return res.status(401).json({
                message: 'Unauthorized',
                error: info?.message || 'Authentication failed'
            });
        }
<<<<<<< HEAD
=======

        // 🛡️ Redis Blocklist Check
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            const isRevoked = await AuthService.isTokenRevoked(token);
            if (isRevoked) {
                return res.status(401).json({
                    message: 'Unauthorized',
                    error: 'This session has been revoked. Please log in again.',
                    code: 'TOKEN_REVOKED'
                });
            }
        }

>>>>>>> dev-ui2
        if (!user.emailVerified) {
            // Allow basic profile access even if unverified (for sync/status display)
            // Also allow public safety features like trending alerts
            const isAllowedPath = (req.path === '/profile' && req.method === 'GET') ||
<<<<<<< HEAD
                (req.path === '/trending' && req.method === 'GET');
=======
                (req.path === '/trending' && req.method === 'GET') ||
                (req.path === '/daily-digest' && req.method === 'GET') ||
                (req.path === '/preferences' && req.method === 'GET') ||
                (req.path === '/subscribe' && req.method === 'POST') ||
                (req.path === '/' && req.method === 'GET'); // For transaction history
>>>>>>> dev-ui2

            if (isAllowedPath) {
                req.user = user;
                return next();
            }

            return res.status(403).json({
                message: 'Forbidden',
                error: 'Please verify your email address to access this resource.'
            });
        }
<<<<<<< HEAD
=======

        if (!user.acceptedTermsVersion) {
            const isAllowedPath = (req.path === '/profile' && req.method === 'GET') ||
                (req.path === '/accept-terms' && req.method === 'POST') ||
                (req.path === '/logout' && req.method === 'POST');

            if (!isAllowedPath) {
                return res.status(403).json({
                    message: 'Forbidden',
                    error: 'Please accept the updated Privacy Policy and Terms of Service to continue.',
                    code: 'TERMS_NOT_ACCEPTED'
                });
            }
        }

>>>>>>> dev-ui2
        req.user = user;
        next();
    })(req, res, next);
};

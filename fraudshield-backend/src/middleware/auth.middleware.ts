import { Request, Response, NextFunction } from 'express';
import passport from 'passport';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
    passport.authenticate('jwt', { session: false }, (err: any, user: any, info: any) => {
        if (err) return next(err);
        if (!user) {
            return res.status(401).json({
                message: 'Unauthorized',
                error: info?.message || 'Authentication failed'
            });
        }
        if (!user.emailVerified) {
            // Allow basic profile access even if unverified (for sync/status display)
            // Also allow public safety features like trending alerts
            const isAllowedPath = (req.path === '/profile' && req.method === 'GET') ||
                (req.path === '/trending' && req.method === 'GET') ||
                (req.path === '/daily-digest' && req.method === 'GET') ||
                (req.path === '/preferences' && req.method === 'GET') ||
                (req.path === '/subscribe' && req.method === 'POST') ||
                (req.path === '/' && req.method === 'GET'); // For transaction history

            if (isAllowedPath) {
                req.user = user;
                return next();
            }

            return res.status(403).json({
                message: 'Forbidden',
                error: 'Please verify your email address to access this resource.'
            });
        }
        req.user = user;
        next();
    })(req, res, next);
};

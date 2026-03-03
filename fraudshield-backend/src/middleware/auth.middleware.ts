import { Request, Response, NextFunction } from 'express';
import passport from '../config/passport';
import { AuthService } from '../services/auth.service';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
    passport.authenticate('jwt', { session: false }, async (err: any, user: any, info: any) => {
        if (err) return next(err);
        if (!user) {
            return res.status(401).json({
                message: 'Unauthorized',
                error: info?.message || 'Authentication failed'
            });
        }
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

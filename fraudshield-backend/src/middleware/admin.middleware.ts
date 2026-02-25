import { Request, Response, NextFunction } from 'express';

export const isAdmin = (req: Request, res: Response, next: NextFunction) => {
    const user = req.user as any;

    if (user && user.role === 'admin') {
        next();
    } else {
        res.status(403).json({
            message: 'Forbidden',
            error: 'You do not have administrative privileges to access this resource.'
        });
    }
};

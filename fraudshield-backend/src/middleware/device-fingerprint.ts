import { Request, Response, NextFunction } from 'express';

export const deviceFingerprint = (req: Request, res: Response, next: NextFunction) => {
    const deviceId = req.headers['x-device-id'];

    if (!deviceId) {
        // Auth routes and health check are exempt - device ID might not be ready or needed
        const exemptPaths = ['/api/v1/auth/', '/api/v1/health'];
        const isExempt = exemptPaths.some(p => req.path.startsWith(p));

        if (!isExempt) {
            return res.status(400).json({ message: 'Missing device fingerprint header (X-Device-Id)' });
        }
        console.warn('Request missing X-Device-Id header from ip:', req.ip);
    }

    (req as any).deviceId = deviceId;
    next();
};

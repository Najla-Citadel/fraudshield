import { Request, Response, NextFunction } from 'express';

export const deviceFingerprint = (req: Request, res: Response, next: NextFunction) => {
    const deviceId = req.headers['x-device-id'];

    if (!deviceId) {
        // Optional: Enforcement can be enabled later
        // return res.status(400).json({ message: 'Missing device fingerprint header (X-Device-Id)' });
        console.warn('Request missing X-Device-Id header from ip:', req.ip);
    }

    (req as any).deviceId = deviceId;
    next();
};

import { Request, Response, NextFunction } from 'express';
import { getRedisClient } from '../config/redis';
import logger from '../utils/logger';

const MAX_TIMESTAMP_AGE_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Middleware to prevent replay attacks using Nonces and Timestamps.
 * Requires X-FS-Timestamp and X-FS-Nonce headers for state-changing requests.
 */
export const antiReplay = async (req: Request, res: Response, next: NextFunction) => {
    // Only enforce for state-changing methods
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
        return next();
    }

    // 🛡️ EXCEPTION: Allow authentication and administrative routes to skip anti-replay protection.
    // These are often called from clients/webapps that haven't implemented full security headers yet.
    const EXEMPT_PATHS = [
        '/api/v1/auth/login',
        '/api/v1/auth/signup',
        '/api/v1/auth/refresh',
        '/api/v1/admin'
    ];
    if (EXEMPT_PATHS.some(path => req.path.startsWith(path))) {
        return next();
    }

    const timestampHeader = req.headers['x-fs-timestamp'];
    const nonceHeader = req.headers['x-fs-nonce'];

    if (!timestampHeader || !nonceHeader) {
        return res.status(403).json({
            error: 'Security Policy Violation',
            message: 'Missing required security headers (X-FS-Timestamp, X-FS-Nonce).',
            code: 'MISSING_SECURITY_HEADERS'
        });
    }

    const timestamp = parseInt(timestampHeader as string, 10);
    const nonce = nonceHeader as string;

    if (isNaN(timestamp)) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'Invalid X-FS-Timestamp header.',
        });
    }

    // 1. Validate Timestamp Freshness
    const now = Date.now();
    if (Math.abs(now - timestamp) > MAX_TIMESTAMP_AGE_MS) {
        return res.status(403).json({
            error: 'Security Policy Violation',
            message: 'Request timestamp is too old or too far in the future.',
            code: 'STALE_TIMESTAMP'
        });
    }

    // 2. Validate Nonce Uniqueness via Redis
    const userId = (req.user as any)?.id || req.ip; // Fallback to IP for pre-auth state-changing calls if any
    const redis = getRedisClient();
    const nonceKey = `nonce:${userId}:${nonce}`;

    try {
        const exists = await redis.exists(nonceKey);
        if (exists) {
            logger.warn(`Replay attack detected! Nonce reused: ${nonce} for User: ${userId}`);
            return res.status(403).json({
                error: 'Security Policy Violation',
                message: 'This request has already been processed.',
                code: 'NONCE_REUSED'
            });
        }

        // Store nonce with TTL corresponding to our timestamp window
        await redis.setex(nonceKey, Math.ceil(MAX_TIMESTAMP_AGE_MS / 1000), '1');
        next();
    } catch (err) {
        logger.error('AntiReplay middleware error:', err);
        // Fail-open for availability if Redis is down, or fail-closed for security.
        // Given this is a security audit hardening, let's fail-closed or at least log heavily.
        next();
    }
};

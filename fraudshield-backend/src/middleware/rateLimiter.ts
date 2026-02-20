import rateLimit from 'express-rate-limit';

/**
 * General auth limiter: applies to all /auth/* routes.
 * 100 requests per 15 minutes per IP.
 */
export const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    standardHeaders: 'draft-7', // Include RateLimit-* headers (RFC 9110)
    legacyHeaders: false,
    message: {
        error: 'Too Many Requests',
        message: 'Too many requests from this IP, please try again after 15 minutes.',
    },
});

/**
 * Strict limiter for login/signup endpoints.
 * 10 attempts per 15 minutes per IP to prevent credential stuffing and brute force.
 */
export const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: {
        error: 'Too Many Requests',
        message: 'Too many login or signup attempts from this IP, please try again after 15 minutes.',
    },
    skipSuccessfulRequests: true, // Only count failed (non-2xx) responses
});

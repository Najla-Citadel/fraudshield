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
    validate: false,
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
    windowMs: 2 * 60 * 1000, // 2 minutes
    max: 10, // 5 attempts per minute average
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: {
        error: 'Too Many Requests',
        message: 'Too many login or signup attempts from this IP, please try again after 2 minutes.',
    },
    validate: false,
    skipSuccessfulRequests: true, // Only count failed (non-2xx) responses
});

/**
 * Throttles scam report submissions to prevent spam.
 * 5 reports per 10 minutes per authenticated user.
 */
export const reportLimiter = rateLimit({
    windowMs: 10 * 60 * 1000, // 10 minutes
    max: 5,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    keyGenerator: (req: any) => {
        // Use user ID (authenticated route)
        return req.user?.id || 'anonymous';
    },
    validate: false,
    message: {
        error: 'Too Many Requests',
        message: 'You have reached the limit for submitting reports. Please try again after 10 minutes.',
    },
});

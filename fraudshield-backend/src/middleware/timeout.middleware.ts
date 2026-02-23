import { Request, Response, NextFunction } from 'express';

/**
 * Global request timeout middleware.
 * If a request takes longer than the specified limit, it will be timed out.
 * 
 * @param timeoutMs The timeout duration in milliseconds (default 30s)
 */
export const requestTimeout = (timeoutMs: number = 30000) => {
    return (req: Request, res: Response, next: NextFunction) => {
        const timeoutId = setTimeout(() => {
            if (!res.headersSent) {
                console.warn(`[Timeout] Request ${req.method} ${req.path} timed out after ${timeoutMs}ms`);
                res.status(504).json({
                    error: 'Gateway Timeout',
                    message: 'The request took too long to process and has been timed out.',
                });
            }
        }, timeoutMs);

        // Clear timeout when request finishes successfully or with an error
        res.on('finish', () => clearTimeout(timeoutId));
        res.on('close', () => clearTimeout(timeoutId));

        next();
    };
};

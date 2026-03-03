import { Request, Response, NextFunction } from 'express';
import { MetricsService } from '../services/metrics.service';

/**
 * Middleware to track HTTP request performance
 */
export const metricsMiddleware = (req: Request, res: Response, next: NextFunction) => {
    const start = process.hrtime();

    // Record metrics on response finish
    res.on('finish', () => {
        const diff = process.hrtime(start);
        const duration = diff[0] + diff[1] / 1e9;

        // Extract route pattern (e.g. /api/v1/auth/login instead of raw URL)
        // Express doesn't populate req.route until the handler is reached.
        // We fallback to path if route is missing (e.g. for mid-stack errors)
        const route = (req as any).route?.path || req.path;
        const labels = {
            method: req.method,
            route: route,
            status_code: res.statusCode.toString(),
        };

        MetricsService.httpResponseTime.observe(labels, duration);
        MetricsService.httpRequestsTotal.inc(labels);
    });

    next();
};

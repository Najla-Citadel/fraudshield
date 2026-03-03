import { Request, Response, NextFunction } from 'express';
import { AsyncLocalStorage } from 'async_hooks';
import { randomUUID } from 'crypto';

/**
 * Context interface for request tracing
 */
interface TraceContext {
    correlationId: string;
}

/**
 * Store for correlation IDs across asynchronous execution contexts
 */
export const traceStore = new AsyncLocalStorage<TraceContext>();

/**
 * Middleware to generate or extract a correlation ID and inject it into the context
 */
export const tracer = (req: Request, res: Response, next: NextFunction) => {
    // Check if an X-Correlation-ID header exists, otherwise generate a new one
    const correlationId = (req.headers['x-correlation-id'] as string) || randomUUID();

    // Store the ID in the async context
    const context: TraceContext = { correlationId };

    // Run the rest of the request within the context
    traceStore.run(context, () => {
        // Set the header in the response for client visibility
        res.setHeader('X-Correlation-ID', correlationId);
        next();
    });
};

/**
 * Utility to get the current correlation ID from any location in the code
 */
export const getCorrelationId = (): string | undefined => {
    return traceStore.getStore()?.correlationId;
};

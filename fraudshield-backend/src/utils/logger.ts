import winston from 'winston';
import { getCorrelationId } from '../middleware/tracer.middleware';

const { combine, timestamp, printf, colorize, json } = winston.format;

// Custom log format for development
const devFormat = printf(({ level, message, timestamp, ...metadata }) => {
    const correlationId = getCorrelationId();
    const tracePrefix = correlationId ? ` [trace:${correlationId.substring(0, 8)}]` : '';

    let msg = `${timestamp}${tracePrefix} [${level}]: ${message}`;
    if (Object.keys(metadata).length > 0) {
        msg += ` ${JSON.stringify(metadata)}`;
    }
    return msg;
});

// Format to inject correlationId into metadata
const injectTrace = winston.format((info) => {
    const correlationId = getCorrelationId();
    if (correlationId) {
        info.correlationId = correlationId;
    }
    return info;
});

// Configure the Winston logger
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'development' ? 'debug' : 'info'),
    format: combine(
        timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        injectTrace(),
        process.env.NODE_ENV === 'production' ? json() : combine(colorize(), devFormat)
    ),
    transports: [
        new winston.transports.Console(),
        // We could add file transports here if needed, e.g.:
        // new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        // new winston.transports.File({ filename: 'logs/combined.log' }),
    ],
});

export default logger;

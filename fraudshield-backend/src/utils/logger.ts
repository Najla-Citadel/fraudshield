import winston from 'winston';
    const correlationId = getCorrelationId();
    const tracePrefix = correlationId ? ` [trace:${correlationId.substring(0, 8)}]` : '';

    let msg = `${timestamp}${tracePrefix} [${level}]: ${message}`;
    if (Object.keys(metadata).length > 0) {
        msg += ` ${JSON.stringify(metadata)}`;
    }
    return msg;
});

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

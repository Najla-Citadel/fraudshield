import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import dotenv from 'dotenv';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './config/swagger';
import passport from './config/passport';
import logger from './utils/logger';

// Load environment variables
dotenv.config();

// Import database
import { prisma } from './config/database';

// Import Routes
import authRoutes from './routes/auth.routes';
import reportRoutes from './routes/report.routes';
import featureRoutes from './routes/feature.routes';
import rewardsRoutes from './routes/rewards.routes';
import adminRoutes from './routes/admin.routes';
import uploadRoutes from './routes/upload.routes';
import userRoutes from './routes/user.routes';
import alertRoutes from './routes/alert.routes';
import transactionRoutes from './routes/transaction.routes';
import configRoutes from './routes/config.routes';
import { requestTimeout } from './middleware/timeout.middleware';

const app: Application = express();

// Trust proxy for rate limiting accuracy behind reverse proxies/LB
app.set('trust proxy', 1);

// Global Request Timeout (30s)
app.use(requestTimeout(30000));

// Security middleware
app.use(helmet());

// Passport middleware
app.use(passport.initialize());

// CORS configuration
const corsOptions = {
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
        const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || [];

        // In development, allow no origin (like mobile apps/Postman) or if it's in the list
        if (process.env.NODE_ENV !== 'production') {
            return callback(null, true);
        }

        // Mobile apps typically don't send an origin
        if (!origin) {
            return callback(null, true);
        }

        // In production, require strict match from CORS_ORIGIN env var
        if (allowedOrigins.length > 0 && allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
};
app.use(cors(corsOptions));

// Body parsing middleware with size limit to prevent memory exhaustion
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    // Stream morgan logs to Winston
    app.use(morgan('combined', {
        stream: {
            write: (message) => logger.info(message.trim())
        }
    }));
}

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV,
    });
});

// Serve static files from the 'uploads' directory
app.use('/uploads', express.static('uploads'));

// Serve static files from the 'public' directory
app.use(express.static('public'));

// API Documentation (Swagger)
const apiPrefix = `/api/${process.env.API_VERSION || 'v1'}`;
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use(`${apiPrefix}/docs`, swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// API Routes
app.use(`${apiPrefix}/auth`, authRoutes);
app.use(`${apiPrefix}/reports`, reportRoutes);
app.use(`${apiPrefix}/features`, featureRoutes);
app.use(`${apiPrefix}/rewards`, rewardsRoutes);
app.use(`${apiPrefix}/admin`, adminRoutes);
app.use(`${apiPrefix}/upload`, uploadRoutes);
app.use(`${apiPrefix}/users`, userRoutes); // Added user routes
app.use(`${apiPrefix}/alerts`, alertRoutes);
app.use(`${apiPrefix}/transactions`, transactionRoutes);
app.use(`${apiPrefix}/config`, configRoutes);

// API version endpoint
app.get(`${apiPrefix}/status`, async (req: Request, res: Response) => {
    try {
        await prisma.$queryRaw`SELECT 1`;
        res.json({
            status: 'healthy',
            version: process.env.API_VERSION || 'v1',
            database: 'connected',
            timestamp: new Date().toISOString(),
        });
    } catch (error) {
        res.status(500).json({
            status: 'unhealthy',
            version: process.env.API_VERSION || 'v1',
            database: 'disconnected',
            error: 'Database connection failed',
        });
    }
});

// 404 handler
app.use((req: Request, res: Response) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.path} not found`,
    });
});

// Global error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
    // Log the error with structured logging
    logger.error(`${req.method} ${req.path} failed`, {
        message: err.message,
        stack: err.stack,
        params: req.params,
        query: req.query
    });

    res.status(err.status || 500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong. Please try again later.',
    });
});

export default app;

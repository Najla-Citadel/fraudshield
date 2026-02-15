import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import dotenv from 'dotenv';
import passport from './config/passport';

// Load environment variables
dotenv.config();

// Import database
import { prisma } from './config/database';

// Import Routes
import authRoutes from './routes/auth.routes';
import reportRoutes from './routes/report.routes';
import featureRoutes from './routes/feature.routes';
import adminRoutes from './routes/admin.routes';
import uploadRoutes from './routes/upload.routes';

const app: Application = express();

// Security middleware
app.use(helmet());

// Passport middleware
app.use(passport.initialize());

// CORS configuration
const corsOptions = {
    origin: process.env.CORS_ORIGIN?.split(',') || '*',
    credentials: true,
};
app.use(cors(corsOptions));

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
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

// API Routes
const apiPrefix = `/api/${process.env.API_VERSION || 'v1'}`;
app.use(`${apiPrefix}/auth`, authRoutes);
app.use(`${apiPrefix}/reports`, reportRoutes);
app.use(`${apiPrefix}/features`, featureRoutes);
app.use(`${apiPrefix}/admin`, adminRoutes);
app.use(`${apiPrefix}/upload`, uploadRoutes);

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
    // Log the error with more context
    console.error(`[${new Date().toISOString()}] Error ${req.method} ${req.path}:`, {
        message: err.message,
        stack: err.stack,
        body: req.body, // Be careful with sensitive data in real production apps
        params: req.params,
        query: req.query
    });

    res.status(err.status || 500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong. Please try again later.',
    });
});

export default app;

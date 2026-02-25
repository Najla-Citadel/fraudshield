import http from 'http';
import { Server } from 'socket.io';
import app from './app';
import { initializeFirebase } from './config/firebase.config';
import { AlertEngineService } from './services/alert-engine.service';
import { AlertWorkerService } from './services/alert-worker.service';
import logger from './utils/logger';

const PORT = process.env.PORT || 3000;

const httpServer = http.createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: process.env.CORS_ORIGIN?.split(',') || '*',
        methods: ['GET', 'POST'],
    },
});

// Basic Socket.io setup
io.on('connection', (socket) => {
    logger.info('New socket client connected', { socketId: socket.id });

    socket.on('join', (userId: string) => {
        socket.join(userId);
        logger.info('User joined socket room', { userId, socketId: socket.id });
    });

    socket.on('disconnect', () => {
        logger.info('Socket client disconnected', { socketId: socket.id });
    });
});

// Export io for use in controllers
export { io };

// Initialize Firebase Admin globally
initializeFirebase();

const server = httpServer.listen(Number(PORT), '0.0.0.0', () => {
    logger.info('FraudShield Backend Server Started', {
        port: PORT,
        env: process.env.NODE_ENV || 'development',
        healthCheck: `http://0.0.0.0:${PORT}/health`,
        apiStatus: `http://0.0.0.0:${PORT}/api/${process.env.API_VERSION || 'v1'}/status`
    });

    // Start background jobs
    logger.info('Starting background jobs...');
    AlertWorkerService.initialize().catch(err => {
        logger.error('❌ Failed to initialize Alert Worker:', err);
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.warn('SIGTERM received: shutting down');
    server.close(async () => {
        await AlertWorkerService.shutdown();
        logger.info('HTTP server closed');
    });
});

process.on('SIGINT', () => {
    logger.warn('SIGINT received: shutting down');
    server.close(async () => {
        await AlertWorkerService.shutdown();
        logger.info('HTTP server closed');
        process.exit(0);
    });
});

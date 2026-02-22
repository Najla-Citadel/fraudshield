import http from 'http';
import { Server } from 'socket.io';
import app from './app';
import { initializeFirebase } from './config/firebase.config';
import { AlertEngineService } from './services/alert-engine.service';

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
    console.log(`🔌 New client connected: ${socket.id}`);

    socket.on('join', (userId: string) => {
        socket.join(userId);
        console.log(`👤 User ${userId} joined their personal room`);
    });

    socket.on('disconnect', () => {
        console.log(`❌ Client disconnected: ${socket.id}`);
    });
});

// Export io for use in controllers
export { io };

// Initialize Firebase Admin globally
initializeFirebase();

const server = httpServer.listen(Number(PORT), '0.0.0.0', () => {
    console.log('🚀 FraudShield Backend Server');
    console.log(`📡 Server running on port ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://0.0.0.0:${PORT}/health`);
    console.log(`📊 API Status: http://0.0.0.0:${PORT}/api/${process.env.API_VERSION || 'v1'}/status`);

    // Start background jobs
    console.log('⏱️ Starting background jobs...');
    AlertEngineService.dispatchTrendingAlerts().catch(console.error); // Run immediately
    setInterval(() => {
        AlertEngineService.dispatchTrendingAlerts().catch(console.error);
    }, 60 * 1000); // Check for trending alerts every minute (for demo purposes)
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});

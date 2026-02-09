import app from './app';

const PORT = process.env.PORT || 3000;

const server = app.listen(Number(PORT), '0.0.0.0', () => {
    console.log('🚀 FraudShield Backend Server');
    console.log(`📡 Server running on port ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Health check: http://0.0.0.0:${PORT}/health`);
    console.log(`📊 API Status: http://0.0.0.0:${PORT}/api/${process.env.API_VERSION || 'v1'}/status`);
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

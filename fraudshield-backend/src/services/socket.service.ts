import { io } from '../server';

export class SocketService {
    static sendAlert(userId: string, alert: {
        title: string;
        message: string;
        type: 'warning' | 'info' | 'critical';
        metadata?: any;
    }) {
        const payload = {
            ...alert,
            timestamp: new Date().toISOString(),
        };

        // Emit to the user's specific room
        io.to(userId).emit('alert', payload);

        console.log(`📢 Alert pushed to user ${userId}: ${alert.title}`);
    }

    static broadcastAlert(alert: any) {
        io.emit('alert', alert);
        console.log(`📢 Global alert broadcasted: ${alert.title}`);
    }
}

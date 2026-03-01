import { prisma } from '../config/database';
import { AlertCategory, AlertSeverity } from '@prisma/client';
import logger from '../utils/logger';

export class AlertService {
    /**
     * Fetch all alerts for a user
     */
    static async getUserAlerts(userId: string) {
        return prisma.alert.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }

    /**
     * Create a new alert for a user
     */
    static async createAlert(data: {
        userId: string;
        category: AlertCategory;
        severity: AlertSeverity;
        title: string;
        message: string;
        metadata?: any;
    }) {
        const alert = await prisma.alert.create({
            data: {
                userId: data.userId,
                category: data.category,
                severity: data.severity,
                title: data.title,
                message: data.message,
                metadata: data.metadata || {},
            },
        });
        
        logger.info(`🔔 New Alert created for User ${data.userId}: ${data.title}`);
        return alert;
    }

    /**
     * Mark all alerts as read for a user
     */
    static async markAllAsRead(userId: string) {
        return prisma.alert.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
    }

    /**
     * Resolve an individual alert with a specific action
     */
    static async resolveAlert(alertId: string, userId: string, action: string) {
        const alert = await prisma.alert.findUnique({
            where: { id: alertId }
        });

        if (!alert || alert.userId !== userId) {
            throw new Error('Alert not found or unauthorized');
        }

        // Logic for specific actions
        if (action === 'BLOCK') {
            const metadata = alert.metadata as any;
            if (metadata.senderNumber) {
                // Future: Integrate with a global blacklist service
                logger.info(`🚫 Blocking sender ${metadata.senderNumber} based on Alert ${alertId}`);
            }
        }

        return prisma.alert.update({
            where: { id: alertId },
            data: { 
                actionTaken: action,
                isRead: true
            },
        });
    }
}

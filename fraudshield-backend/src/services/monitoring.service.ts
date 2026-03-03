import axios from 'axios';
import { prisma } from '../config/database';
import { getRedisClient } from '../config/redis';
import { EmailService } from './email.service';
import logger from '../utils/logger';

export class MonitoringService {
    private static lastAlertTime: Map<string, number> = new Map();
    private static ALERT_COOLDOWN = 15 * 60 * 1000; // 15 minutes cooldown per error type

    /**
     * Notifies admins of a critical error via email and webhook.
     */
    static async notifyError(error: Error, context: any = {}) {
        try {
            const errorKey = error.message || 'Unknown Error';
            const now = Date.now();
            const lastAlert = this.lastAlertTime.get(errorKey) || 0;

            if (now - lastAlert < this.ALERT_COOLDOWN) {
                logger.debug(`Skipping duplicate alert for: ${errorKey}`);
                return;
            }

            this.lastAlertTime.set(errorKey, now);

            const alertTitle = `🚨 [CRITICAL ALERT] ${process.env.NODE_ENV?.toUpperCase()} Error`;
            const alertMessage = `
                <h3>Critical Error Detected</h3>
                <p><strong>Message:</strong> ${error.message}</p>
                <p><strong>Stack:</strong> ${error.stack}</p>
                <p><strong>Context:</strong> ${JSON.stringify(context, null, 2)}</p>
                <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
            `;

            // 1. Send Email Alert
            const adminEmail = process.env.ADMIN_ALERT_EMAIL;
            if (adminEmail) {
                await EmailService.init();
                // We use nodemailer directly or wrap it in EmailService
                // For simplicity, let's assume EmailService has a generic sendEmail method or we use a temporary one
                // Actually, let's just use the transporter from EmailService if we can expose it or add a method
                await (EmailService as any).transporter?.sendMail({
                    from: process.env.SMTP_FROM || '"FraudShield Monitor" <noreply@fraudshieldprotect.com>',
                    to: adminEmail,
                    subject: alertTitle,
                    html: alertMessage
                });
            }

            // 2. Send Webhook Alert (Discord/Slack)
            const webhookUrl = process.env.CRITICAL_ALERT_WEBHOOK_URL;
            if (webhookUrl) {
                await axios.post(webhookUrl, {
                    content: `**${alertTitle}**\n**Message:** ${error.message}\n**Environment:** ${process.env.NODE_ENV}\nCheck logs for details.`
                }).catch(err => logger.error('Failed to send webhook alert:', err.message));
            }

            logger.info(`Critical alert dispatched: ${errorKey}`);
        } catch (err: any) {
            logger.error('MonitoringService.notifyError failed:', err.message);
        }
    }

    /**
     * Checks the health of critical infrastructure.
     */
    static async checkInfrastructure() {
        const results = {
            database: 'unknown',
            redis: 'unknown',
            timestamp: new Date().toISOString()
        };

        try {
            await prisma.$queryRaw`SELECT 1`;
            results.database = 'healthy';
        } catch (err) {
            results.database = 'unhealthy';
            this.notifyError(new Error('Database connectivity lost'), { service: 'Postgres' });
        }

        try {
            const redis = getRedisClient();
            await redis.ping();
            results.redis = 'healthy';
        } catch (err) {
            results.redis = 'unhealthy';
            this.notifyError(new Error('Redis connectivity lost'), { service: 'Redis' });
        }

        return results;
    }
}

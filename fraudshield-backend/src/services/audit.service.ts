import { prisma } from '../config/database';

export interface AuditLogData {
    adminId: string;
    action: string;
    targetType: string;
    targetId?: string;
    payload?: any;
}

export class AuditService {
    /**
     * Records an administrative action in the audit log.
     */
    static async logAction(data: AuditLogData): Promise<void> {
        try {
            await (prisma as any).auditLog.create({
                data: {
                    adminId: data.adminId,
                    action: data.action,
                    targetType: data.targetType,
                    targetId: data.targetId,
                    payload: data.payload || {},
                }
            });
        } catch (error) {
            console.error('AuditService: Failed to record audit log:', error);
            // We don't throw here to avoid failing the main admin action if logging fails,
            // though in some security-critical environments you might want to.
        }
    }
}

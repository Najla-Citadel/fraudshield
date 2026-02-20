import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class UserController {
    static async deleteAccount(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = req.user?.id;

            if (!userId) {
                return res.status(401).json({ message: 'Unauthorized' });
            }

            // Use a transaction to ensure all improved data is deleted or anonymized atomically
            await prisma.$transaction(async (tx) => {
                // 1. Delete personal data linked to the user
                // Profile (One-to-One)
                await tx.profile.deleteMany({ where: { userId } });

                // UserSubscriptions (One-to-Many)
                await tx.userSubscription.deleteMany({ where: { userId } });

                // Alerts (One-to-Many) - these are personal notifications
                await tx.alert.deleteMany({ where: { userId } });

                // Redemptions (One-to-Many) - personal reward history
                // We delete these to remove PII links, assuming delivered rewards are handled.
                await tx.redemption.deleteMany({ where: { userId } });

                // Note: We DO NOT delete ScamReports, Comments (if any), or Transactions.
                // These are critical for the community and audit trails.

                // 2. Anonymize the User record
                // We keep the record ID to maintain foreign key integrity for Reports/Transactions
                await tx.user.update({
                    where: { id: userId },
                    data: {
                        email: `deleted_${userId}@fraudshield.deleted`, // Unique dummy email
                        passwordHash: 'deleted',
                        fullName: 'Deleted User',
                        role: 'deleted',
                        // clear other PII fields if added in future
                    },
                });
            });

            // 3. Respond with success
            // Context: Client should clear local tokens and redirect to login
            res.status(200).json({ message: 'Account deleted successfully' });
        } catch (error) {
            next(error);
        }
    }
}

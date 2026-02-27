import { Request, Response, NextFunction } from 'express';
import { ApkScanService } from '../services/apk-scan.service';
import { PrismaClient, CheckType } from '@prisma/client';

const prisma = new PrismaClient();

const ALLOWED_APK_MIMETYPES = [
    'application/vnd.android.package-archive',
    'application/octet-stream',   // Many clients send APKs with this type
    'application/zip',             // APK is a ZIP file
];

export class ApkScanController {
    static async scanApk(req: Request, res: Response, next: NextFunction) {
        const user = req.user as { id: string };

        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'No file uploaded.' });
            }

            // Check either MIME or extension
            const isApkByExtension = req.file.originalname.toLowerCase().endsWith('.apk');
            const isApkByMime = ALLOWED_APK_MIMETYPES.includes(req.file.mimetype);

            if (!isApkByExtension && !isApkByMime) {
                return res.status(400).json({ success: false, message: 'Only APK files are accepted.' });
            }

            if (req.file.size > 50 * 1024 * 1024) {
                return res.status(400).json({ success: false, message: 'File exceeds 50MB limit.' });
            }

            const result = await ApkScanService.analyze(req.file.buffer, req.file.originalname);

            // Log to transaction journal
            try {
                const userId = (req.user as any)?.id;
                if (userId) {
                    await prisma.transactionJournal.create({
                        data: {
                            userId,
                            checkType: CheckType.DOC,
                            target: req.file!.originalname,
                            riskScore: result.score,
                            status: result.score >= 55 ? 'SUSPICIOUS' : 'SAFE',
                            metadata: {
                                level: result.level,
                                reasons: result.reasons,
                                packageName: result.packageName,
                                sha256: result.sha256,
                                source: 'apk_scan',
                            },
                        },
                    });
                }
            } catch { /* non-fatal */ }

            return res.json({ success: true, data: result });
        } catch (error) {
            next(error);
        }
    }
}

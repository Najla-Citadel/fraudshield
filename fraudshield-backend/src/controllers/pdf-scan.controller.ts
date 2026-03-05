import { Request, Response, NextFunction } from 'express';
import { PdfScanService } from '../services/pdf-scan.service';
import { PrismaClient, CheckType } from '@prisma/client';

const prisma = new PrismaClient();

export class PdfScanController {
    static async scanPdf(req: Request, res: Response, next: NextFunction) {
        const user = req.user as { id: string };

        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: 'No PDF file uploaded.' });
            }

            const isPdfByExtension = req.file.originalname.toLowerCase().endsWith('.pdf');
            const isPdfByMime = req.file.mimetype === 'application/pdf';

            if (!isPdfByExtension && !isPdfByMime) {
                return res.status(400).json({ success: false, message: 'Only PDF files are accepted.' });
            }

            if (req.file.size > 50 * 1024 * 1024) {
                return res.status(400).json({ success: false, message: 'File exceeds 50MB limit.' });
            }

            const result = await PdfScanService.analyze(req.file.buffer);

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
                                sha256: result.sha256,
                                source: 'pdf_scan',
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

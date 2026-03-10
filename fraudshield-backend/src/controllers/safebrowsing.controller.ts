import { Request, Response, NextFunction } from 'express';
import { SafeBrowsingService } from '../services/safebrowsing.service';

export class SafeBrowsingController {
    /**
     * POST /features/check-url
     * Body: { url: string }
     */
    static async checkUrl(req: Request, res: Response, next: NextFunction) {
        try {
            const { url } = req.body;

            if (!url || typeof url !== 'string') {
                return res.status(400).json({
                    error: 'Bad Request',
                    message: 'A valid "url" string is required in the request body.',
                });
            }

            const result = await SafeBrowsingService.checkUrl(url);

            res.json({
                ...result,
                checkedAt: new Date().toISOString(),
            });
        } catch (error) {
            next(error);
        }
    }
}

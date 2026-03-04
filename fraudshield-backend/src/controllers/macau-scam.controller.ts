import { Request, Response, NextFunction } from 'express';
import { MacauScamService } from '../services/macau-scam.service';

export class MacauScamController {
    /**
     * POST /api/v1/check/macau-scam
     * Performs a deep Macau Scam risk evaluation based on text content and/or transaction history
     */
    static async evaluate(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { text, transactionId } = req.body;

            if (!text && !transactionId) {
                return res.status(400).json({ message: 'Must provide either text content or a transactionId for evaluation.' });
            }

            const evaluation = await MacauScamService.evaluate(userId, text, transactionId);

            res.json(evaluation);
        } catch (error) {
            next(error);
        }
    }
}

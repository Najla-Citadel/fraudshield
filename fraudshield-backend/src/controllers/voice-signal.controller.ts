import { Request, Response, NextFunction } from 'express';
import { getRedisClient } from '../config/redis';
import logger from '../utils/logger';

export class VoiceSignalController {
    /**
     * POST /api/v1/features/behavioral/call-signal
     * Tracks that a user is currently in a call or has recently ended one.
     * This signal is used by MacauScamService to correlate with transactions.
     */
    static async reportCallSignal(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any).id;
            const { event, duration, incomingNumber, inContacts } = req.body;

            const redis = getRedisClient();
            const key = `macau_signal:voice:${userId}`;

            if (event === 'CALL_START' || event === 'CALL_ACTIVE') {
                // Set signal with 1 hour expiry
                await redis.set(key, JSON.stringify({
                    status: 'ACTIVE',
                    timestamp: new Date().toISOString(),
                    incomingNumber: incomingNumber ? 'HIDDEN' : 'UNKNOWN', // Privacy first
                    inContacts: inContacts || false
                }), 'EX', 3600);

                logger.info(`VoiceSignal: Active call signal received for user ${userId}. inContacts: ${inContacts}`);
            } else if (event === 'CALL_ENDED') {
                // Keep the signal for 30 mins after call ends as Macau scams 
                // often involve immediate transfers post-call.
                await redis.set(key, JSON.stringify({
                    status: 'RECENTLY_ENDED',
                    timestamp: new Date().toISOString(),
                    durationSeconds: duration || 0,
                    inContacts: inContacts || false
                }), 'EX', 1800);

                logger.info(`VoiceSignal: Call ended signal received for user ${userId}. Duration: ${duration}s, inContacts: ${inContacts}`);
            }

            res.status(204).send();
        } catch (error) {
            next(error);
        }
    }
}

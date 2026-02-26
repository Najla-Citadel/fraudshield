import { Request, Response, NextFunction } from 'express';

export class ConfigController {
    static getAppConfig(req: Request, res: Response, next: NextFunction) {
        try {
            res.json({
                minVersion: process.env.MIN_APP_VERSION || '1.0.0',
                latestVersion: process.env.LATEST_APP_VERSION || '1.0.0',
                updateUrl: {
                    android: 'https://play.google.com/store/apps/details?id=com.citadel.fraudshield',
                    ios: 'https://apps.apple.com/app/id6470000000'
                },
                maintenance: {
                    enabled: false,
                    message: 'FraudShield is currently undergoing maintenance. Please check back later.'
                }
            });
        } catch (error) {
            next(error);
        }
    }
}

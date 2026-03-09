import { Request, Response, NextFunction } from 'express';
import { AttestationService } from '../services/attestation.service';

/**
 * @openapi
 * tags:
 *   name: Attestation
 *   description: App integrity and device attestation
 */
export class AttestationController {
    /**
     * @openapi
     * /api/v1/attestation/challenge:
     *   get:
     *     summary: Get a fresh nonce for attestation
     *     tags: [Attestation]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Nonce generated successfully
     */
    static async getChallenge(req: Request, res: Response, next: NextFunction) {
        try {
            const userId = (req.user as any)?.id;
            console.log(`🛡️ AttestationController: Generating challenge for user ${userId}`);
            const nonce = await AttestationService.generateChallenge(userId);
            res.json({ nonce });
        } catch (error) {
            next(error);
        }
    }

    /**
     * @openapi
     * /api/v1/attestation/verify:
     *   post:
     *     summary: Verify app integrity token
     *     tags: [Attestation]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required: [platform, token, nonce]
     *             properties:
     *               platform: { type: string, enum: [android, ios] }
     *               token: { type: string }
     *               nonce: { type: string }
     *               packageName: { type: string }
     *     responses:
     *       200:
     *         description: Verification complete
     */
    static async verify(req: Request, res: Response, next: NextFunction) {
        try {
            const { platform, token, nonce, packageName, securitySignals } = req.body;
            console.log(`🛡️ AttestationController: Received verification request. Platform: ${platform}, Package: ${packageName}`);
            if (securitySignals) {
                console.log('🛡️ AttestationController: Security Signals:', JSON.stringify(securitySignals, null, 2));
            }

            if (!platform || !token || !nonce) {
                return res.status(400).json({ error: 'Missing required attestation data' });
            }

            let result;
            if (platform === 'android') {
                if (!packageName) {
                    return res.status(400).json({ error: 'Package name is required for Android' });
                }
                result = await AttestationService.verifyPlayIntegrity(token, nonce, packageName);
            } else if (platform === 'ios') {
                result = await AttestationService.verifyAppleDeviceCheck(token, nonce);
            } else {
                return res.status(400).json({ error: 'Unsupported platform' });
            }

            if (!result.isValid) {
                console.warn(`🛡️  Attestation Failed: ${result.error || result.verdict}`);
                return res.status(403).json({
                    message: `Device attestation failed: ${result.error || result.verdict}`,
                    ...result
                });
            }

            res.json({
                message: 'Device verified successfully',
                ...result
            });
        } catch (error) {
            next(error);
        }
    }
}

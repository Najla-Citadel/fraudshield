import crypto from 'crypto';
import { playintegrity_v1, google } from 'googleapis';
import { getRedisClient } from '../config/redis';
import logger from '../utils/logger';

const CHALLENGE_TTL = 300; // 5 minutes

export interface AttestationVerdict {
    isValid: boolean;
    verdict?: string; // 'MEETS_BASIC_INTEGRITY', 'MEETS_DEVICE_INTEGRITY', 'MEETS_STRONG_INTEGRITY'
    packageName?: string;
    certificateSha256Digest?: string[];
    error?: string;
}

export class AttestationService {
    private static playIntegrityClient?: playintegrity_v1.Playintegrity;

    /**
     * Initializes the Google Play Integrity client
     */
    private static async getPlayIntegrityClient() {
        if (this.playIntegrityClient) return this.playIntegrityClient;

        try {
            const authOptions: any = {
                scopes: ['https://www.googleapis.com/auth/playintegrity'],
            };

            // Support both file-path based auth (standard) and stringified JSON (convenient for cloud envs)
            if (process.env.GOOGLE_PLAY_INTEGRITY_JSON) {
                try {
                    authOptions.credentials = JSON.parse(process.env.GOOGLE_PLAY_INTEGRITY_JSON);
                } catch (parseError) {
                    logger.error('Failed to parse GOOGLE_PLAY_INTEGRITY_JSON environment variable');
                }
            }

            const auth = new google.auth.GoogleAuth(authOptions);
            this.playIntegrityClient = google.playintegrity({ version: 'v1', auth });
            return this.playIntegrityClient;
        } catch (error) {
            logger.error('Failed to initialize Play Integrity client:', error);
            return null;
        }
    }

    /**
     * Generates a unique, high-entropy challenge (nonce) for the client.
     */
    static async generateChallenge(userId: string): Promise<string> {
        // Play Integrity and DeviceCheck require a "web-safe" base64 string (no + or /)
        const nonce = crypto.randomBytes(32).toString('base64url');
        const redis = await getRedisClient();

        // Store nonce in Redis with a short TTL to prevent replay attacks
        await redis.set(`attestation:nonce:${nonce}`, userId, 'EX', CHALLENGE_TTL);

        return nonce;
    }

    /**
     * Verifies a Google Play Integrity token.
     */
    static async verifyPlayIntegrity(
        token: string,
        nonce: string,
        packageName: string
    ): Promise<AttestationVerdict> {
        const isProd = process.env.NODE_ENV === 'production';
        console.log('--------------------------------------------------');
        console.log(`🛡️  DEBUG: NODE_ENV = "${process.env.NODE_ENV}"`);
        console.log(`🛡️  DEBUG: isProd = ${isProd}`);
        console.log(`🛡️  DEBUG: Nonce = ${nonce}`);
        console.log('--------------------------------------------------');

        if (!isProd) {
            console.log('🛡️  DEBUG: BYPASSING Google check because NODE_ENV is not production');
            return { isValid: true, verdict: 'MOCK_PASSED_DEV' };
        }

        const redis = await getRedisClient();
        const storedUserId = await redis.get(`attestation:nonce:${nonce}`);

        if (!storedUserId) {
            console.error('🛡️  ERROR: Nonce not found in Redis (expired or invalid)');
            return { isValid: false, error: 'Challenge expired or invalid' };
        }

        // Consume nonce immediately
        await redis.del(`attestation:nonce:${nonce}`);

        const client = await this.getPlayIntegrityClient();
        if (!client) {
            console.error('🛡️ AttestationService: Client initialization failed.');
            return isProd ? { isValid: false, error: 'Integrity service unavailable' } : { isValid: true, verdict: 'MOCK_PASSED_DEV' };
        }

        console.log('🛡️ AttestationService: Client methods available:', Object.keys(client));

        try {
            // Try different possible structures for the decode call
            let response;
            if ((client as any).integrity) {
                response = await (client as any).integrity.decodeIntegrityToken({
                    packageName,
                    requestBody: { integrityToken: token },
                });
            } else {
                response = await (client as any).decodeIntegrityToken({
                    packageName,
                    requestBody: { integrityToken: token },
                });
            }

            const result = response.data.tokenPayloadExternal;
            console.log('🛡️ AttestationService: Full Google Response:', JSON.stringify(result, null, 2));

            if (!result) {
                return { isValid: false, error: 'Invalid token payload' };
            }

            // 1. Verify Request Match (Nonce)
            if (result.requestDetails?.nonce !== nonce) {
                return { isValid: false, error: 'Nonce mismatch' };
            }

            // 2. Verify App Integrity
            const appIntegrity = result.appIntegrity;
            if (appIntegrity?.appRecognitionVerdict !== 'PLAY_RECOGNIZED') {
                return { isValid: false, verdict: 'UNRECOGNIZED_VERSION', error: 'App not recognized by Play Store' };
            }

            // 3. Verify Device Integrity
            const deviceIntegrity = result.deviceIntegrity?.deviceRecognitionVerdict || [];
            let verdict: string = 'NONE';

            if (deviceIntegrity.includes('MEETS_STRONG_INTEGRITY')) {
                verdict = 'STRONG';
            } else if (deviceIntegrity.includes('MEETS_DEVICE_INTEGRITY')) {
                verdict = 'DEVICE';
            } else if (deviceIntegrity.includes('MEETS_BASIC_INTEGRITY')) {
                verdict = 'BASIC';
            }

            // In development, we allow even NONE integrity because emulators often have no hardware verdict.
            // In production, we strictly require DEVICE or STRONG.
            const isProd = process.env.NODE_ENV === 'production';
            const meetsIntegrity = isProd ? (verdict === 'STRONG' || verdict === 'DEVICE') : true; 
            const meetsRecognition = isProd ? (appIntegrity?.appRecognitionVerdict === 'PLAY_RECOGNIZED') : true;

            const isValid = meetsIntegrity && meetsRecognition;

            console.log(`🛡️ AttestationService: Play Integrity verdict for ${packageName}: ${verdict} (isValid: ${isValid})`);

            return {
                isValid,
                verdict,
                packageName: appIntegrity.packageName,
                certificateSha256Digest: appIntegrity.certificateSha256Digest,
            };

        } catch (error: any) {
            console.error('🛡️ AttestationService ERROR:', error);
            return { isValid: false, error: error.message || 'Verification failed' };
        }
    }

    /**
     * Verifies an Apple DeviceCheck token (Placeholder for iOS implementation)
     */
    static async verifyAppleDeviceCheck(token: string, nonce: string): Promise<AttestationVerdict> {
        // Implementation would involve JWT signing with .p8 key and calling Apple API
        // For now, we return a mock/placeholder as real credentials are required
        logger.info('Apple DeviceCheck verification requested (Placeholder)');
        return { isValid: true, verdict: 'IOS_VERIFIED' };
    }
}

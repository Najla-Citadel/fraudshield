import logger from '../utils/logger';

/**
 * Validates that all required environment variables are present.
 * Throws an error and exits the process if any are missing.
 */
export const validateEnv = () => {
    const requiredEnvVars = [
        'JWT_SECRET',
        'JWT_REFRESH_SECRET',
        'DATABASE_URL',
        'OPENAI_API_KEY',
        'DB_ENCRYPTION_KEY',
    ];

    // 🛡️ SECURITY: These are critical for production but we can allow missing in dev with a warning
    const criticalSecurityVars = [
        'METRICS_API_KEY',
        'TURNSTILE_SECRET_KEY',
    ];

    const missingRequired = requiredEnvVars.filter((varName) => !process.env[varName]);
    const missingSecurity = criticalSecurityVars.filter((varName) => !process.env[varName]);

    if (missingRequired.length > 0) {
        const errorMsg = `❌ CRITICAL: Missing required environment variables: ${missingRequired.join(', ')}`;
        logger.error(errorMsg);
        throw new Error(errorMsg);
    }

    if (missingSecurity.length > 0) {
        const warnMsg = `⚠️ WARNING: Missing security environment variables: ${missingSecurity.join(', ')}`;
        if (process.env.NODE_ENV === 'production') {
            logger.error(`❌ CRITICAL: ${warnMsg} (Required in production)`);
            throw new Error(`CRITICAL: ${missingSecurity.join(', ')} must be set in production.`);
        } else {
            logger.warn(`${warnMsg} - Security features (Metrics/CAPTCHA) may be disabled or bypassed.`);
        }
    }

    logger.info('✅ Environment variables validated');
};

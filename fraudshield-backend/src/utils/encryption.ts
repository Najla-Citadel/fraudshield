import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const TAG_LENGTH = 16;
const SALT_LENGTH = 64;

/**
 * Utility for Application-Level Field Encryption (AES-256-GCM)
 * Used to protect PII at rest within the database.
 */
export class EncryptionUtils {
    private static getSecret() {
        const secret = process.env.DB_ENCRYPTION_KEY;
        if (!secret || secret.length < 32) {
            throw new Error('Encryption error: DB_ENCRYPTION_KEY must be at least 32 characters.');
        }
        return secret;
    }

    /**
     * Encrypts a plaintext string
     */
    static encrypt(text: string): string {
        const iv = crypto.randomBytes(IV_LENGTH);
        const salt = crypto.randomBytes(SALT_LENGTH);
        const key = crypto.scryptSync(this.getSecret(), salt, 32);

        const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
        const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
        const tag = cipher.getAuthTag();

        // Format: salt:iv:tag:encrypted
        return `${salt.toString('hex')}:${iv.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`;
    }

    /**
     * Encrypts a plaintext string deterministically for searchable fields.
     * WARNING: Identical inputs result in identical outputs. use only for fields that need exact match searching.
     */
    static deterministicEncrypt(text: string): string {
        const salt = crypto.scryptSync(this.getSecret(), 'search_salt', SALT_LENGTH);
        const key = crypto.scryptSync(this.getSecret(), salt, 32);
        const iv = Buffer.alloc(IV_LENGTH, 0); // Static IV for deterministic encryption

        const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
        const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
        const tag = cipher.getAuthTag();

        return `det:${salt.toString('hex')}:${tag.toString('hex')}:${encrypted.toString('hex')}`;
    }

    /**
     * Decrypts an encrypted string (handles both probabilistic and deterministic)
     */
    static decrypt(encryptedData: string): string {
        try {
            if (encryptedData.startsWith('det:')) {
                const [, saltHex, tagHex, encryptedHex] = encryptedData.split(':');
                const salt = Buffer.from(saltHex, 'hex');
                const tag = Buffer.from(tagHex, 'hex');
                const encrypted = Buffer.from(encryptedHex, 'hex');
                const iv = Buffer.alloc(IV_LENGTH, 0);

                const key = crypto.scryptSync(this.getSecret(), salt, 32);
                const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
                decipher.setAuthTag(tag);
                return decipher.update(encrypted) + decipher.final('utf8');
            }

            const [saltHex, ivHex, tagHex, encryptedHex] = encryptedData.split(':');
            if (!saltHex || !ivHex || !tagHex || !encryptedHex) return encryptedData;

            const salt = Buffer.from(saltHex, 'hex');
            const iv = Buffer.from(ivHex, 'hex');
            const tag = Buffer.from(tagHex, 'hex');
            const encrypted = Buffer.from(encryptedHex, 'hex');

            const key = crypto.scryptSync(this.getSecret(), salt, 32);
            const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
            decipher.setAuthTag(tag);

            return decipher.update(encrypted) + decipher.final('utf8');
        } catch (err) {
            console.error('Decryption failed. Returning original data.');
            return encryptedData;
        }
    }
}

import * as admin from 'firebase-admin';
import path from 'path';
import fs from 'fs';

let isInitialized = false;

export const initializeFirebase = () => {
    if (isInitialized) return;

    try {
        // Determine the path to the service account key
        // In production, you might want to load this from an environment variable
        // For local dev, we use the file we just downloaded
        const serviceAccountPath = path.resolve(__dirname, '../../fraudshield-271b0-firebase-adminsdk-fbsvc-2a70150a06.json');

        if (!fs.existsSync(serviceAccountPath)) {
            console.warn('⚠️ Firebase service account key not found. Push notifications will be disabled.');
            return;
        }

        const serviceAccount = require(serviceAccountPath);

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });

        console.log('🔥 Firebase Admin SDK initialized successfully');
        isInitialized = true;
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
};

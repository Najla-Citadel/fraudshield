import * as admin from 'firebase-admin';

let isInitialized = false;

export const initializeFirebase = () => {
    if (isInitialized) return;

    try {
        let serviceAccount: any;

        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            try {
                serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
                console.log('✅ Loading Firebase credentials from environment variable');
            } catch (parseError) {
                console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT env var. Ensure it is a valid JSON string.');
                return;
            }
        } else {
            if (process.env.NODE_ENV === 'production') {
                throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is required in production.');
            }
            console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT environment variable not found. Push notifications will be disabled.');
            return;
        }

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });

        console.log('🔥 Firebase Admin SDK initialized successfully');
        isInitialized = true;
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin SDK:', error);
    }
};

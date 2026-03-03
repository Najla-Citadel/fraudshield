import * as admin from 'firebase-admin';
>>>>>>> dev-ui2

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
<<<<<<< HEAD
                console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT env var:', parseError);
            }
        }

        if (!serviceAccount) {
            // Determine the path to the service account key (fallback for local dev)
            const serviceAccountPath = path.resolve(__dirname, '../../fraudshield-271b0-firebase-adminsdk-fbsvc-2a70150a06.json');

            if (!fs.existsSync(serviceAccountPath)) {
                console.warn('⚠️ Firebase service account key not found. Push notifications will be disabled.');
                return;
            }

            serviceAccount = require(serviceAccountPath);
=======
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

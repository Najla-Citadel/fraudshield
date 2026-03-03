import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
<<<<<<< HEAD
import passport from 'passport';
=======
>>>>>>> dev-ui2
import { authLimiter, loginLimiter } from '../middleware/rateLimiter';
import { validateSignup, validateLogin, validateChangePassword } from '../middleware/validators';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Apply general rate limiter to all auth routes
router.use(authLimiter);

// Strict rate limiter on sensitive unauthenticated endpoints
router.post('/signup', loginLimiter, validateSignup, AuthController.signup);
router.post('/verify-email', loginLimiter, AuthController.verifyEmail);
router.post('/login', loginLimiter, validateLogin, AuthController.login);
router.post('/google', loginLimiter, AuthController.googleLogin);
router.post('/refresh', AuthController.refresh);

// Password Reset Flow (Unauthenticated but heavily rate limited)
router.post('/forgot-password', loginLimiter, AuthController.requestPasswordReset);
router.post('/reset-password', loginLimiter, AuthController.verifyAndResetPassword);

// Protected routes
router.use(authenticate);

router.get('/profile', AuthController.getProfile);
router.patch('/profile', AuthController.updateProfile);
router.post('/request-verification', AuthController.requestEmailVerification);
router.post('/change-password', authenticate, validateChangePassword, AuthController.changePassword);
<<<<<<< HEAD
=======
router.post('/accept-terms', AuthController.acceptTerms);
>>>>>>> dev-ui2
router.post('/logout', AuthController.logout);

export default router;

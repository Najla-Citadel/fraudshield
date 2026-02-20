import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import passport from 'passport';
import { authLimiter, loginLimiter } from '../middleware/rateLimiter';

const router = Router();

// Apply general rate limiter to all auth routes
router.use(authLimiter);

// Strict rate limiter on sensitive unauthenticated endpoints
router.post('/signup', loginLimiter, AuthController.signup);
router.post('/login', loginLimiter, AuthController.login);

// Protected routes
router.use(passport.authenticate('jwt', { session: false }));

router.get('/profile', AuthController.getProfile);
router.patch('/profile', AuthController.updateProfile);
router.post('/change-password', AuthController.changePassword);
router.post('/logout', AuthController.logout);

export default router;

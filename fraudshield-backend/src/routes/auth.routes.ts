import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import passport from 'passport';

const router = Router();

router.post('/signup', AuthController.signup);
router.post('/login', AuthController.login);

// Protected routes
router.use(passport.authenticate('jwt', { session: false }));

router.get('/profile', AuthController.getProfile);
router.patch('/profile', AuthController.updateProfile);
router.post('/change-password', AuthController.changePassword);
router.post('/logout', AuthController.logout);

export default router;

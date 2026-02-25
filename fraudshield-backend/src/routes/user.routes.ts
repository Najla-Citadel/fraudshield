import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protected routes
router.get('/export', authenticate, UserController.exportData);
router.post('/consent/terms', authenticate, UserController.updateTermsConsent);
router.delete('/me', authenticate, UserController.deleteAccount);

export default router;

import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import passport from 'passport';

const router = Router();

// Protected admin routes
router.use(passport.authenticate('jwt', { session: false }));

router.get('/alerts', AdminController.getAlerts);
router.get('/transactions/:id', AdminController.getTransaction);
router.post('/label-transaction', AdminController.labelTransaction);

export default router;

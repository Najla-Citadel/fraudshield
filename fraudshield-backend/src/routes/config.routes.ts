import { Router } from 'express';
import { ConfigController } from '../controllers/config.controller';

const router = Router();

// Publicly accessible config
router.get('/app', ConfigController.getAppConfig);

export default router;

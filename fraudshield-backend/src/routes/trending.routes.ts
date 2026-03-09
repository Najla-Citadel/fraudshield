import { Router } from 'express';
import { TrendingController } from '../controllers/trending.controller';

const router = Router();

// GET /api/v1/trending/scams
router.get('/scams', TrendingController.getTrendingScams);

export default router;

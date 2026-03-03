import { Router } from 'express';
import { UploadController, upload } from '../controllers/upload.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all upload routes
router.use(authenticate);

router.post('/single', upload.single('file'), UploadController.uploadFile);
router.post('/multiple', upload.array('files', 5), UploadController.uploadMultipleFiles);

export default router;

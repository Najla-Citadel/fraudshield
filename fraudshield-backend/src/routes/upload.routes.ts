import { Router } from 'express';
import { UploadController, upload } from '../controllers/upload.controller';
import passport from 'passport';

const router = Router();

// Protect all upload routes
router.use(passport.authenticate('jwt', { session: false }));

router.post('/single', upload.single('file'), UploadController.uploadFile);
router.post('/multiple', upload.array('files', 5), UploadController.uploadMultipleFiles);

export default router;

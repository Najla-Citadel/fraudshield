import { Request, Response, NextFunction } from 'express';
import multer from 'multer';
<<<<<<< HEAD
import path from 'path';
import fs from 'fs';

// Configure storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// File filter
const fileFilter = (req: any, file: any, cb: any) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, and PDF are allowed.'), false);
=======
import { S3Client } from '@aws-sdk/client-s3';
import multerS3 from 'multer-s3';
import path from 'path';

// 1. Initialize S3 Client for DigitalOcean Spaces
const s3 = new S3Client({
    endpoint: process.env.DO_SPACES_ENDPOINT, // e.g. https://sgp1.digitaloceanspaces.com
    region: process.env.DO_SPACES_REGION || 'us-east-1', // Fallback but endpoint is primary for DO
    credentials: {
        accessKeyId: process.env.DO_SPACES_KEY || '',
        secretAccessKey: process.env.DO_SPACES_SECRET || '',
    },
});

// 2. Configure multer-s3 storage
const storage = multerS3({
    s3: s3,
    bucket: process.env.DO_SPACES_BUCKET || 'fraudshield-uploads',
    acl: 'public-read', // Files are publicly accessible via URL
    contentType: multerS3.AUTO_CONTENT_TYPE,
    metadata: (req, file, cb) => {
        cb(null, { fieldName: file.fieldname });
    },
    key: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const fileName = file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname);
        cb(null, `uploads/${fileName}`); // Organized in an 'uploads' folder in the Space
    }
});

// 3. File filter (restored from original)
const fileFilter = (req: any, file: any, cb: any) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf', 'application/vnd.android.package-archive'];
    if (allowedTypes.includes(file.mimetype) || file.originalname.endsWith('.apk')) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, PDF, and APK are allowed.'), false);
>>>>>>> dev-ui2
    }
};

export const upload = multer({
    storage: storage,
    limits: {
<<<<<<< HEAD
        fileSize: 10 * 1024 * 1024 // 10MB
=======
        fileSize: 50 * 1024 * 1024 // Increased to 50MB for APK support
>>>>>>> dev-ui2
    },
    fileFilter: fileFilter
});

export class UploadController {
<<<<<<< HEAD
=======
    /**
     * POST /api/v1/upload/single
     * Handles single file upload to DigitalOcean Spaces
     */
>>>>>>> dev-ui2
    static async uploadFile(req: Request, res: Response, next: NextFunction) {
        try {
            if (!req.file) {
                return res.status(400).json({ message: 'No file uploaded' });
            }

<<<<<<< HEAD
            const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

            res.status(201).json({
                message: 'File uploaded successfully',
                filename: req.file.filename,
=======
            // multer-s3 adds 'location' to the file object
            const fileUrl = (req.file as any).location;

            res.status(201).json({
                message: 'File uploaded successfully to Spaces',
                filename: (req.file as any).key,
>>>>>>> dev-ui2
                mimetype: req.file.mimetype,
                size: req.file.size,
                url: fileUrl
            });
        } catch (error) {
            next(error);
        }
    }

<<<<<<< HEAD
    static async uploadMultipleFiles(req: Request, res: Response, next: NextFunction) {
        try {
            const files = req.files as Express.Multer.File[];
=======
    /**
     * POST /api/v1/upload/multiple
     * Handles multiple file uploads to DigitalOcean Spaces
     */
    static async uploadMultipleFiles(req: Request, res: Response, next: NextFunction) {
        try {
            const files = req.files as any[];
>>>>>>> dev-ui2
            if (!files || files.length === 0) {
                return res.status(400).json({ message: 'No files uploaded' });
            }

            const fileInfos = files.map(file => ({
<<<<<<< HEAD
                filename: file.filename,
                mimetype: file.mimetype,
                size: file.size,
                url: `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
            }));

            res.status(201).json({
                message: 'Files uploaded successfully',
=======
                filename: file.key,
                mimetype: file.mimetype,
                size: file.size,
                url: file.location
            }));

            res.status(201).json({
                message: 'Files uploaded successfully to Spaces',
>>>>>>> dev-ui2
                files: fileInfos
            });
        } catch (error) {
            next(error);
        }
    }
}

import { Request, Response, NextFunction } from 'express';
import multer from 'multer';
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
    }
};

export const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB
    },
    fileFilter: fileFilter
});

export class UploadController {
    static async uploadFile(req: Request, res: Response, next: NextFunction) {
        try {
            if (!req.file) {
                return res.status(400).json({ message: 'No file uploaded' });
            }

            const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

            res.status(201).json({
                message: 'File uploaded successfully',
                filename: req.file.filename,
                mimetype: req.file.mimetype,
                size: req.file.size,
                url: fileUrl
            });
        } catch (error) {
            next(error);
        }
    }

    static async uploadMultipleFiles(req: Request, res: Response, next: NextFunction) {
        try {
            const files = req.files as Express.Multer.File[];
            if (!files || files.length === 0) {
                return res.status(400).json({ message: 'No files uploaded' });
            }

            const fileInfos = files.map(file => ({
                filename: file.filename,
                mimetype: file.mimetype,
                size: file.size,
                url: `${req.protocol}://${req.get('host')}/uploads/${file.filename}`
            }));

            res.status(201).json({
                message: 'Files uploaded successfully',
                files: fileInfos
            });
        } catch (error) {
            next(error);
        }
    }
}

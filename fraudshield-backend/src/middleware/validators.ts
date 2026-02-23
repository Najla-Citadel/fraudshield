import { body, validationResult } from 'express-validator';
import { Request, Response, NextFunction } from 'express';

/**
 * Reusable middleware to check validation results and return 422 on failure.
 */
export const handleValidationErrors = (req: Request, res: Response, next: NextFunction): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        res.status(422).json({
            error: 'Validation Error',
            errors: errors.array().map((e) => ({
                field: e.type === 'field' ? (e as any).path : undefined,
                message: e.msg,
            })),
        });
        return;
    }
    next();
};

/**
 * Validation rules for POST /auth/signup
 */
export const validateSignup = [
    body('email')
        .trim()
        .notEmpty().withMessage('Email is required.')
        .isEmail().withMessage('Must be a valid email address.')
        .normalizeEmail(),

    body('password')
        .notEmpty().withMessage('Password is required.')
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
        .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
        .matches(/[0-9]/).withMessage('Password must contain at least one number.'),

    body('fullName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters.')
        .matches(/^[a-zA-Z\s'-]+$/).withMessage('Full name contains invalid characters.'),

    handleValidationErrors,
];

/**
 * Validation rules for POST /auth/login
 */
export const validateLogin = [
    body('email')
        .trim()
        .notEmpty().withMessage('Email is required.')
        .isEmail().withMessage('Must be a valid email address.')
        .normalizeEmail(),

    body('password')
        .notEmpty().withMessage('Password is required.'),

    handleValidationErrors,
];

/**
 * Validation rules for POST /auth/change-password
 */
export const validateChangePassword = [
    body('currentPassword')
        .notEmpty().withMessage('Current password is required.'),

    body('newPassword')
        .notEmpty().withMessage('New password is required.')
        .isLength({ min: 8 }).withMessage('New password must be at least 8 characters.')
        .matches(/[A-Z]/).withMessage('New password must contain at least one uppercase letter.')
        .matches(/[0-9]/).withMessage('New password must contain at least one number.'),

    handleValidationErrors,
];

/**
 * Validation rules for POST /reports (submitReport)
 */
export const validateReport = [
    body('type')
        .trim()
        .notEmpty().withMessage('Report type is required.'),

    body('category')
        .trim()
        .notEmpty().withMessage('Category is required.'),

    body('description')
        .trim()
        .notEmpty().withMessage('Description is required.')
        .isLength({ min: 10 }).withMessage('Description must be at least 10 characters long.'),

    body('target')
        .optional()
        .trim()
        .isString().withMessage('Target must be a string.'),

    body('isPublic')
        .optional()
        .isBoolean().withMessage('isPublic must be a boolean.'),

    body('latitude')
        .optional()
        .isNumeric().withMessage('Latitude must be a number.'),

    body('longitude')
        .optional()
        .isNumeric().withMessage('Longitude must be a number.'),

    handleValidationErrors,
];

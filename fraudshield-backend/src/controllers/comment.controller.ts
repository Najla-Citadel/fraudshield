import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';

export class CommentController {
    static async addComment(req: Request, res: Response, next: NextFunction) {
        try {
            const { reportId, text } = req.body;
            const userId = (req.user as any).id;

            if (!text || text.trim().length === 0) {
                return res.status(400).json({ message: 'Comment text is required' });
            }

            const comment = await (prisma as any).comment.create({
                data: {
                    userId,
                    reportId,
                    text: text.trim(),
                },
                include: {
                    user: {
                        select: {
                            fullName: true,
                            profile: {
                                select: {
                                    avatar: true
                                }
                            }
                        }
                    }
                }
            });

            res.status(201).json(comment);
        } catch (error) {
            next(error);
        }
    }

    static async getComments(req: Request, res: Response, next: NextFunction) {
        try {
            const { reportId } = req.params;

            const comments = await (prisma as any).comment.findMany({
                where: { reportId },
                orderBy: { createdAt: 'desc' },
                include: {
                    user: {
                        select: {
                            fullName: true,
                            profile: {
                                select: {
                                    avatar: true
                                }
                            }
                        }
                    }
                }
            });

            res.json(comments);
        } catch (error) {
            next(error);
        }
    }
}

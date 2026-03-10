import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/database';
import { ContentFilter } from '../utils/content-filter';
import { io } from '../server';

export class CommentController {
    static async addComment(req: Request, res: Response, next: NextFunction) {
        try {
            const { reportId, text } = req.body;
            const userId = (req.user as any).id;

            if (!text || text.trim().length === 0) {
                return res.status(400).json({ message: 'Comment text is required' });
            }

            const trimmedText = text.trim();

            if (trimmedText.length > 500) {
                return res.status(400).json({ message: 'Comment must be 500 characters or less' });
            }

            if (trimmedText.length < 3) {
                return res.status(400).json({ message: 'Comment is too short' });
            }

            const filterResult = ContentFilter.sanitize(trimmedText);
            if (filterResult.blocked) {
                return res.status(400).json({ message: filterResult.reason });
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
                            profile: {
                                select: {
                                    avatar: true,
                                    preferredName: true,
                                    reputation: true,
                                }
                            }
                        }
                    }
                }
            });

            const response = {
                id: comment.id,
                text: comment.text,
                createdAt: comment.createdAt,
                reportId: comment.reportId,
                commenter: {
                    avatar: comment.user?.profile?.avatar || 'Felix',
                    displayName: comment.user?.profile?.preferredName || 'Community Member',
                    reputation: comment.user?.profile?.reputation || 0,
                },
            };

            // Emit real-time comment update
            io.to(`report_${reportId}`).emit('new_comment', response);

            res.status(201).json(response);
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
                            profile: {
                                select: {
                                    avatar: true,
                                    preferredName: true,
                                    reputation: true,
                                }
                            }
                        }
                    }
                }
            });

            const anonymized = comments.map((c: any) => ({
                id: c.id,
                text: c.text,
                createdAt: c.createdAt,
                reportId: c.reportId,
                commenter: {
                    avatar: c.user?.profile?.avatar || 'Felix',
                    displayName: c.user?.profile?.preferredName || 'Community Member',
                    reputation: c.user?.profile?.reputation || 0,
                },
            }));

            res.json(anonymized);
        } catch (error) {
            next(error);
        }
    }
}

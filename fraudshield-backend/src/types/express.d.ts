import { User } from '@prisma/client';

declare global {
    namespace Express {
        interface User {
            id: string;
            role: string;
            email: string;
        }

        interface Request {
            user?: User;
        }
    }
}

import passport from 'passport';
import { Strategy as LocalStrategy } from 'passport-local';
import { Strategy as JwtStrategy, ExtractJwt } from 'passport-jwt';
import bcrypt from 'bcrypt';
import { prisma } from './database';
import logger from '../utils/logger';

// Local Strategy for login
passport.use(
    new LocalStrategy(
        {
            usernameField: 'email',
            passwordField: 'password',
        },
        async (email, password, done) => {
            try {
                const user = await prisma.user.findUnique({
                    where: { email },
                    include: { profile: true },
                });

                if (!user) {
                    logger.warn(`Login failed: User not found for email ${email}`);
                    return done(null, false, { message: 'Invalid email or password' });
                }

                const isMatch = await bcrypt.compare(password, user.passwordHash);

                if (!isMatch) {
                    logger.warn(`Login failed: Password mismatch for email ${email}`);
                    return done(null, false, { message: 'Invalid email or password' });
                }

                return done(null, user);
            } catch (error) {
                return done(error);
            }
        }
    )
);

// JWT Strategy for protected routes
passport.use(
    new JwtStrategy(
        {
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
            secretOrKey: process.env.JWT_SECRET as string,
        },
        async (payload, done) => {
            try {
                const user = await prisma.user.findUnique({
                    where: { id: payload.sub },
                    include: {
                        profile: true,
                    }
                });

                if (!user) {
                    return done(null, false);
                }

                return done(null, user);
            } catch (error) {
                return done(error, false);
            }
        }
    )
);

export default passport;

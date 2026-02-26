import swaggerJsdoc from 'swagger-jsdoc';

const apiPrefix = `/api/${process.env.API_VERSION || 'v1'}`;

const options: swaggerJsdoc.Options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'FraudShield API',
            version: '1.0.0',
            description: 'Interactive API documentation for FraudShield Backend',
        },
        servers: [
            {
                url: process.env.NODE_ENV === 'production'
                    ? 'https://api.fraudshieldprotect.com'
                    : `http://localhost:${process.env.PORT || 3000}`,
                description: process.env.NODE_ENV === 'production' ? 'Production Server' : 'Local Development',
            },
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                },
            },
        },
        security: [
            {
                bearerAuth: [],
            },
        ],
    },
    apis: ['./src/controllers/*.ts', './src/routes/*.ts', './src/app.ts'], // Files to scan for annotations
};

export const swaggerSpec = swaggerJsdoc(options);

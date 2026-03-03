import { Registry, collectDefaultMetrics, Histogram, Counter } from 'prom-client';

/**
 * MetricsService manages application performance indicators
 */
export class MetricsService {
    public static readonly registry = new Registry();

    // 1. HTTP Request Latency
    public static readonly httpResponseTime = new Histogram({
        name: 'http_response_time_seconds',
        help: 'Duration of HTTP responses in seconds',
        labelNames: ['method', 'route', 'status_code'],
        buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 10], // Useful for API latency
        registers: [MetricsService.registry],
    });

    // 2. HTTP Request Count
    public static readonly httpRequestsTotal = new Counter({
        name: 'http_requests_total',
        help: 'Total number of HTTP requests',
        labelNames: ['method', 'route', 'status_code'],
        registers: [MetricsService.registry],
    });

    // 3. Database Query Latency
    public static readonly dbQueryDuration = new Histogram({
        name: 'db_query_duration_seconds',
        help: 'Duration of database queries in seconds',
        labelNames: ['operation', 'model'],
        buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1],
        registers: [MetricsService.registry],
    });

    // 4. External API (OpenAI, etc.) Latency
    public static readonly externalApiDuration = new Histogram({
        name: 'external_api_duration_seconds',
        help: 'Duration of external API calls in seconds',
        labelNames: ['service', 'operation'],
        buckets: [0.5, 1, 2, 5, 10, 30],
        registers: [MetricsService.registry],
    });

    /**
     * Initializes default system metrics
     */
    static init() {
        collectDefaultMetrics({
            register: MetricsService.registry,
            prefix: 'fraudshield_',
        });
    }

    /**
     * Helper to measure a promise's execution time
     */
    static async observeExternalCall<T>(service: string, operation: string, promise: Promise<T>): Promise<T> {
        const end = MetricsService.externalApiDuration.startTimer({ service, operation });
        try {
            return await promise;
        } finally {
            end();
        }
    }
}

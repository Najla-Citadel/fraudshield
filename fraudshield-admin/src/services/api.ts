import axios from 'axios';

const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1',
});

// Add a request interceptor to add the JWT token to headers
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('adminToken');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

// Add a response interceptor to handle token expiry
let isRefreshing = false;
let failedQueue: any[] = [];

const processQueue = (error: any, token: string | null = null) => {
    failedQueue.forEach((prom) => {
        if (error) {
            prom.reject(error);
        } else {
            prom.resolve(token);
        }
    });
    failedQueue = [];
};

api.interceptors.response.use(
    (response) => response,
    async (error) => {
        const originalRequest = error.config;

        // If error is 401 and it's not a retry or a refresh request itself
        if (error.response?.status === 401 && !originalRequest._retry && !originalRequest.url.includes('/auth/refresh')) {
            if (isRefreshing) {
                return new Promise((resolve, reject) => {
                    failedQueue.push({ resolve, reject });
                })
                    .then((token) => {
                        originalRequest.headers.Authorization = `Bearer ${token}`;
                        return api(originalRequest);
                    })
                    .catch((err) => Promise.reject(err));
            }

            originalRequest._retry = true;
            isRefreshing = true;

            const refreshToken = localStorage.getItem('adminRefreshToken');
            if (!refreshToken) {
                isRefreshing = false;
                localStorage.removeItem('adminToken');
                localStorage.removeItem('adminUser');
                window.location.href = '/login';
                return Promise.reject(error);
            }

            try {
                const response = await axios.post(`${api.defaults.baseURL}/auth/refresh`, { refreshToken });
                const { token, refreshToken: newRefreshToken } = response.data;

                localStorage.setItem('adminToken', token);
                localStorage.setItem('adminRefreshToken', newRefreshToken);

                api.defaults.headers.common.Authorization = `Bearer ${token}`;
                originalRequest.headers.Authorization = `Bearer ${token}`;

                processQueue(null, token);
                return api(originalRequest);
            } catch (refreshError) {
                processQueue(refreshError, null);
                localStorage.removeItem('adminToken');
                localStorage.removeItem('adminRefreshToken');
                localStorage.removeItem('adminUser');
                window.location.href = '/login';
                return Promise.reject(refreshError);
            } finally {
                isRefreshing = false;
            }
        }

        return Promise.reject(error);
    }
);

export default api;

export const adminService = {
    getStats: () => api.get('/admin/stats'),
    getUsers: () => api.get('/admin/users'),
    getUserById: (id: string) => api.get(`/admin/users/${id}`),
    updateUserRole: (id: string, role: string) => api.patch(`/admin/users/${id}/role`, { role }),
    updateUser: (id: string, data: any) => api.patch(`/admin/users/${id}`, data),
    getReports: (page = 1, limit = 15, sortBy = 'newest') => api.get('/admin/reports', { params: { page, limit, sortBy } }),
    getReportById: (id: string) => api.get(`/admin/reports/${id}`),
    updateReportStatus: (id: string, status: string) => api.patch(`/admin/reports/${id}/status`, { status }),
    labelTransaction: (data: { txId: string; label: string; alertId?: string }) => api.post('/admin/label-transaction', data),
    getSubscriptionPlans: () => api.get('/admin/subscription-plans'),
    createSubscriptionPlan: (data: any) => api.post('/admin/subscription-plans', data),
    updateSubscriptionPlan: (id: string, data: any) => api.put(`/admin/subscription-plans/${id}`, data),
    deleteSubscriptionPlan: (id: string) => api.delete(`/admin/subscription-plans/${id}`),
    getBadges: () => api.get('/admin/badges'),
    createBadge: (data: any) => api.post('/admin/badges', data),
    updateBadge: (id: string, data: any) => api.put(`/admin/badges/${id}`, data),
    deleteBadge: (id: string) => api.delete(`/admin/badges/${id}`),
    getRewards: () => api.get('/admin/rewards'),
    createReward: (data: any) => api.post('/admin/rewards', data),
    updateReward: (id: string, data: any) => api.put(`/admin/rewards/${id}`, data),
    deleteReward: (id: string) => api.delete(`/admin/rewards/${id}`),
    getRedemptions: () => api.get('/admin/redemptions'),
    updateRedemptionStatus: (id: string, status: string) => api.patch(`/admin/redemptions/${id}/status`, { status }),
    getBroadcasts: () => api.get('/admin/broadcasts'),
    createBroadcast: (data: any) => api.post('/admin/broadcasts', data),
    updateBroadcast: (id: string, data: any) => api.put(`/admin/broadcasts/${id}`, data),
    deleteBroadcast: (id: string) => api.delete(`/admin/broadcasts/${id}`),
    getTransactions: () => api.get('/admin/transactions'),
    getFraudLabels: () => api.get('/admin/fraud-labels'),
    createFraudLabel: (data: any) => api.post('/admin/fraud-labels', data),
    deleteFraudLabel: (id: string) => api.delete(`/admin/fraud-labels/${id}`),
    getContentFlags: () => api.get('/admin/content-flags'),
    updateFlagStatus: (id: string, status: string) => api.patch(`/admin/content-flags/${id}`, { status }),
    getGlobalEntities: (params: { type: string; search?: string; offset?: number; limit?: number }) => api.get('/admin/global-entities', { params }),
    createAdvisory: (data: { category: string; description: string; target?: string; type?: string; source?: string }) => api.post('/admin/advisory', data),
};

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

export default api;

export const adminService = {
    getStats: () => api.get('/admin/stats'),
    getUsers: () => api.get('/admin/users'),
    getUserById: (id: string) => api.get(`/admin/users/${id}`),
    updateUserRole: (id: string, role: string) => api.patch(`/admin/users/${id}/role`, { role }),
    updateUser: (id: string, data: any) => api.patch(`/admin/users/${id}`, data),
    getReports: (page = 1, limit = 15) => api.get('/admin/reports', { params: { page, limit } }),
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
};

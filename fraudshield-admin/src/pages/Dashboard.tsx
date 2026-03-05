import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Users, AlertTriangle, CheckCircle, Clock } from 'lucide-react';

interface Stats {
    totalUsers: number;
    totalReports: number;
    pendingReports: number;
}

const Dashboard = () => {
    const [stats, setStats] = useState<Stats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const response = await adminService.getStats();
                setStats(response.data);
            } catch (error) {
                console.error('Error fetching stats:', error);
            } finally {
                setLoading(false);
            }
        };
        fetchStats();
    }, []);

    if (loading) return <div className="text-white">Loading...</div>;

    const statCards = [
        { label: 'Total Users', value: stats?.totalUsers || 0, icon: Users, color: 'text-blue-400', bg: 'bg-blue-400/10' },
        { label: 'Total Reports', value: stats?.totalReports || 0, icon: AlertTriangle, color: 'text-accent-green', bg: 'bg-accent-green/10' },
        { label: 'Pending Reports', value: stats?.pendingReports || 0, icon: Clock, color: 'text-yellow-400', bg: 'bg-yellow-400/10' },
        { label: 'Resolved Reports', value: (stats?.totalReports || 0) - (stats?.pendingReports || 0), icon: CheckCircle, color: 'text-purple-400', bg: 'bg-purple-400/10' },
    ];

    return (
        <div>
            <header className="mb-8">
                <h2 className="text-3xl font-bold">Dashboard Overview</h2>
                <p className="text-slate-400">System statistics and metrics</p>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                {statCards.map((card, idx) => (
                    <div
                        key={idx}
                        className={`glass-card p-6 rounded-2xl animate-slide-up`}
                        style={{ animationDelay: `${idx * 100}ms` }}
                    >
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-slate-400 font-medium text-sm mb-1">{card.label}</p>
                                <h3 className="text-4xl font-black text-white">{card.value}</h3>
                            </div>
                            <div className={`${card.bg} ${card.color} p-4 rounded-xl shadow-inner`}>
                                <card.icon size={28} />
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            <div className="glass-card rounded-2xl p-8 animate-slide-up" style={{ animationDelay: '400ms' }}>
                <h3 className="text-xl font-bold mb-4">Quick Actions</h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                    <button className="glass-card hover:bg-navy-700/50 p-6 rounded-xl text-left flex flex-col items-start group">
                        <div className="bg-accent-green/10 p-3 rounded-lg text-accent-green mb-4 group-hover:bg-accent-green group-hover:text-navy-900 transition-colors">
                            <AlertTriangle size={24} />
                        </div>
                        <h4 className="font-bold text-lg text-white mb-1">Review Pending Reports</h4>
                        <p className="text-sm text-slate-400">Handle outstanding scam reports</p>
                    </button>
                    <button className="glass-card hover:bg-navy-700/50 p-6 rounded-xl text-left flex flex-col items-start group">
                        <div className="bg-blue-400/10 p-3 rounded-lg text-blue-400 mb-4 group-hover:bg-blue-400 group-hover:text-navy-900 transition-colors">
                            <Users size={24} />
                        </div>
                        <h4 className="font-bold text-lg text-white mb-1">Manage User Roles</h4>
                        <p className="text-sm text-slate-400">Update system privileges and access</p>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;

import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { AlertCircle, CheckCircle2, XCircle, Clock } from 'lucide-react';

interface ScamReport {
    id: string;
    type: string;
    target: string | null;
    targetType: string | null;
    description: string;
    category: string;
    status: string;
    createdAt: string;
    user: {
        fullName: string | null;
        email: string;
    };
}

const Reports = () => {
    const [reports, setReports] = useState<ScamReport[]>([]);
    const [loading, setLoading] = useState(true);
    const [meta, setMeta] = useState({ page: 1, totalPages: 1, total: 0 });

    const fetchReports = async (page = 1) => {
        setLoading(true);
        try {
            const response = await adminService.getReports(page);
            setReports(response.data.data);
            setMeta(response.data.meta);
        } catch (error) {
            console.error('Error fetching reports:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReports(1);
    }, []);

    const handleStatusUpdate = async (id: string, status: string) => {
        try {
            await adminService.updateReportStatus(id, status);
            setReports(reports.map(r => r.id === id ? { ...r, status } : r));
        } catch (error) {
            alert('Failed to update status');
        }
    };

    if (loading) return <div className="text-white">Loading...</div>;

    const getStatusIcon = (status: string) => {
        const s = status.toLowerCase();
        switch (s) {
            case 'pending': return <Clock size={16} className="text-yellow-400" />;
            case 'verified': return <CheckCircle2 size={16} className="text-accent-green" />;
            case 'rejected': return <XCircle size={16} className="text-accent-red" />;
            default: return <AlertCircle size={16} className="text-slate-400" />;
        }
    };

    return (
        <div>
            <header className="mb-8">
                <h2 className="text-3xl font-bold">Scam Report Management</h2>
                <p className="text-slate-400">Review and verify reported scam activity</p>
            </header>

            <div className="space-y-4">
                {reports.map((report, idx) => (
                    <div
                        key={report.id}
                        className="glass-card rounded-2xl p-6 animate-slide-up"
                        style={{ animationDelay: `${idx * 100}ms` }}
                    >
                        <div className="flex justify-between items-start mb-4">
                            <div className="flex items-center space-x-3">
                                <div className="bg-navy-700 p-2 rounded-lg">
                                    <AlertCircle size={20} className="text-accent-green" />
                                </div>
                                <div>
                                    <h3 className="font-bold text-lg leading-tight uppercase tracking-tight">{report.category}</h3>
                                    <p className="text-xs text-slate-400">Reported by: <span className="text-slate-300 font-medium">{report.user.fullName || report.user.email}</span></p>
                                </div>
                            </div>
                            <div className={`px-3 py-1 rounded-full text-xs font-bold uppercase flex items-center space-x-2 border ${report.status.toLowerCase() === 'pending' ? 'bg-yellow-400/10 text-yellow-400 border-yellow-400/20' :
                                report.status.toLowerCase() === 'verified' ? 'bg-accent-green/10 text-accent-green border-accent-green/20' :
                                    'bg-accent-red/10 text-accent-red border-accent-red/20'
                                }`}>
                                {getStatusIcon(report.status)}
                                <span>{report.status}</span>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            <div className="lg:col-span-2">
                                <p className="text-slate-300 mb-4 bg-navy-900/50 p-3 rounded-lg border border-navy-700/50 italic text-sm">
                                    "{report.description}"
                                </p>
                                <div className="flex flex-wrap gap-2">
                                    {report.target && (
                                        <div className="bg-navy-700/50 px-3 py-1.5 rounded-lg border border-navy-600 flex items-center space-x-2">
                                            <span className="text-xs text-slate-400 uppercase">{report.targetType}:</span>
                                            <span className="text-sm font-mono text-white">{report.target}</span>
                                        </div>
                                    )}
                                    <div className="bg-navy-700/50 px-3 py-1.5 rounded-lg border border-navy-600 flex items-center space-x-2">
                                        <span className="text-xs text-slate-400 uppercase">Reported:</span>
                                        <span className="text-sm text-white">{new Date(report.createdAt).toLocaleString()}</span>
                                    </div>
                                </div>
                            </div>

                            <div className="flex flex-col justify-end space-y-2">
                                {report.status.toLowerCase() === 'pending' && (
                                    <>
                                        <button
                                            onClick={() => handleStatusUpdate(report.id, 'VERIFIED')}
                                            className="w-full bg-accent-green hover:bg-green-500 text-navy-900 font-bold py-2 rounded-lg transition-colors text-sm"
                                        >
                                            Verify & Approve
                                        </button>
                                        <button
                                            onClick={() => handleStatusUpdate(report.id, 'REJECTED')}
                                            className="w-full bg-navy-700 hover:bg-accent-red hover:text-white text-slate-300 font-bold py-2 rounded-lg transition-colors text-sm border border-navy-600"
                                        >
                                            Reject Report
                                        </button>
                                    </>
                                )}
                                {report.status.toLowerCase() !== 'pending' && (
                                    <button
                                        onClick={() => handleStatusUpdate(report.id, 'PENDING')}
                                        className="w-full bg-navy-700 hover:bg-navy-600 text-slate-300 font-bold py-2 rounded-lg transition-colors text-sm border border-navy-600"
                                    >
                                        Reset to Pending
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>
                ))}

                {reports.length === 0 && (
                    <div className="text-center py-20 bg-navy-800 border-2 border-dashed border-navy-700 rounded-xl">
                        <Clock size={48} className="mx-auto text-slate-600 mb-4" />
                        <h3 className="text-xl font-bold text-slate-400">No reports found</h3>
                        <p className="text-slate-500">All caught up! Check back later.</p>
                    </div>
                )}

                {meta.totalPages > 1 && (
                    <div className="flex items-center justify-between mt-8 p-4 bg-navy-800 rounded-xl border border-navy-700">
                        <button
                            onClick={() => fetchReports(meta.page - 1)}
                            disabled={meta.page === 1}
                            className="px-4 py-2 bg-navy-700 text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-navy-600 transition-colors"
                        >
                            Previous
                        </button>
                        <span className="text-slate-300 font-medium">
                            Page {meta.page} of {meta.totalPages} ({meta.total} total records)
                        </span>
                        <button
                            onClick={() => fetchReports(meta.page + 1)}
                            disabled={meta.page >= meta.totalPages}
                            className="px-4 py-2 bg-accent-green text-navy-900 font-bold rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:bg-green-500 transition-colors"
                        >
                            Next
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Reports;

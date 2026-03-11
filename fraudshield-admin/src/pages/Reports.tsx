import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { AlertCircle, CheckCircle2, XCircle, Clock, Eye, ShieldCheck, Plus, X } from 'lucide-react';
import ReportDetailModal from '../components/ReportDetailModal';

interface ScamReport {
    id: string;
    type: string;
    target: string | null;
    targetType: string | null;
    description: string;
    category: string;
    status: string;
    createdAt: string;
    source?: string;
    user: {
        fullName: string | null;
        email: string;
    };
    flagCount?: number;
}

const Reports = () => {
    const [reports, setReports] = useState<ScamReport[]>([]);
    const [loading, setLoading] = useState(true);
    const [meta, setMeta] = useState({ page: 1, totalPages: 1, total: 0 });
    const [selectedReportId, setSelectedReportId] = useState<string | null>(null);
    const [sortBy, setSortBy] = useState('newest');
    const [showAdvisoryModal, setShowAdvisoryModal] = useState(false);
    const [advisoryForm, setAdvisoryForm] = useState({ category: '', description: '', target: '', type: 'link', source: 'official' });
    const [advisorySubmitting, setAdvisorySubmitting] = useState(false);

    const fetchReports = async (page = 1, sort = sortBy) => {
        setLoading(true);
        try {
            const response = await adminService.getReports(page, 15, sort);
            setReports(response.data.data);
            setMeta(response.data.meta);
        } catch (error) {
            console.error('Error fetching reports:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReports(1, sortBy);
    }, [sortBy]);

    const handleStatusUpdate = async (id: string, status: string) => {
        try {
            await adminService.updateReportStatus(id, status);
            setReports(reports.map(r => r.id === id ? { ...r, status } : r));
        } catch (error) {
            alert('Failed to update status');
        }
    };

    const truncateId = (id: string) => {
        if (!id) return id;
        if (id.length <= 20) return id;
        const hexLikeRegex = /([a-fA-Z0-9]{15,})/;
        return id.replace(hexLikeRegex, (matched) => {
            return `${matched.substring(0, 10)}...${matched.substring(matched.length - 4)}`;
        });
    };

    const handleCreateAdvisory = async () => {
        if (!advisoryForm.category || !advisoryForm.description) {
            alert('Category and description are required');
            return;
        }
        setAdvisorySubmitting(true);
        try {
            await adminService.createAdvisory(advisoryForm);
            setShowAdvisoryModal(false);
            setAdvisoryForm({ category: '', description: '', target: '', type: 'link', source: 'official' });
            fetchReports(1, sortBy);
        } catch (error) {
            alert('Failed to create advisory');
        } finally {
            setAdvisorySubmitting(false);
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
                <div className="flex justify-between items-start">
                    <div>
                        <h2 className="text-3xl font-bold">Scam Report Management</h2>
                        <p className="text-slate-400">Review and verify reported scam activity</p>
                    </div>
                    <button
                        onClick={() => setShowAdvisoryModal(true)}
                        className="flex items-center space-x-2 bg-blue-600 hover:bg-blue-500 text-white font-bold py-2.5 px-4 rounded-lg transition-colors text-sm"
                    >
                        <ShieldCheck size={16} />
                        <span>Create Advisory</span>
                    </button>
                </div>
                <div className="mt-4 flex items-center space-x-4">
                    <span className="text-sm text-slate-400">Sort by:</span>
                    <select
                        value={sortBy}
                        onChange={(e) => setSortBy(e.target.value)}
                        className="bg-navy-800 border border-navy-700 text-white rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-accent-green/50"
                    >
                        <option value="newest">Newest First</option>
                        <option value="flagged">Most Flagged</option>
                    </select>
                </div>
            </header>

            {/* Advisory Creation Modal */}
            {showAdvisoryModal && (
                <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
                    <div className="bg-navy-800 border border-navy-700 rounded-2xl p-6 w-full max-w-lg mx-4">
                        <div className="flex justify-between items-center mb-6">
                            <h3 className="text-xl font-bold flex items-center space-x-2">
                                <ShieldCheck size={20} className="text-blue-400" />
                                <span>Create Official Advisory</span>
                            </h3>
                            <button onClick={() => setShowAdvisoryModal(false)} className="text-slate-400 hover:text-white">
                                <X size={20} />
                            </button>
                        </div>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm text-slate-400 mb-1">Source</label>
                                <select
                                    value={advisoryForm.source}
                                    onChange={(e) => setAdvisoryForm({ ...advisoryForm, source: e.target.value })}
                                    className="w-full bg-navy-900 border border-navy-600 text-white rounded-lg px-3 py-2 text-sm"
                                >
                                    <option value="official">Official (FraudShield Team)</option>
                                    <option value="law_enforcement">Law Enforcement (PDRM/CCID)</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm text-slate-400 mb-1">Category</label>
                                <select
                                    value={advisoryForm.category}
                                    onChange={(e) => setAdvisoryForm({ ...advisoryForm, category: e.target.value })}
                                    className="w-full bg-navy-900 border border-navy-600 text-white rounded-lg px-3 py-2 text-sm"
                                >
                                    <option value="">Select category...</option>
                                    <option value="Phishing / SMS Scam">Phishing / SMS Scam</option>
                                    <option value="Investment Scam">Investment Scam</option>
                                    <option value="Courier / Parcel Scam">Courier / Parcel Scam</option>
                                    <option value="Love Scam">Love Scam</option>
                                    <option value="Job Scam">Job Scam</option>
                                    <option value="Macau Scam">Macau Scam</option>
                                    <option value="E-Commerce Fraud">E-Commerce Fraud</option>
                                    <option value="Other">Other</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm text-slate-400 mb-1">Description</label>
                                <textarea
                                    value={advisoryForm.description}
                                    onChange={(e) => setAdvisoryForm({ ...advisoryForm, description: e.target.value })}
                                    rows={4}
                                    className="w-full bg-navy-900 border border-navy-600 text-white rounded-lg px-3 py-2 text-sm resize-none"
                                    placeholder="Describe the threat advisory..."
                                />
                            </div>
                            <div>
                                <label className="block text-sm text-slate-400 mb-1">Target (optional)</label>
                                <input
                                    type="text"
                                    value={advisoryForm.target}
                                    onChange={(e) => setAdvisoryForm({ ...advisoryForm, target: e.target.value })}
                                    className="w-full bg-navy-900 border border-navy-600 text-white rounded-lg px-3 py-2 text-sm"
                                    placeholder="Phone number, URL, or bank account..."
                                />
                            </div>
                            <div className="flex space-x-3 pt-2">
                                <button
                                    onClick={() => setShowAdvisoryModal(false)}
                                    className="flex-1 bg-navy-700 hover:bg-navy-600 text-slate-300 font-bold py-2.5 rounded-lg transition-colors text-sm border border-navy-600"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={handleCreateAdvisory}
                                    disabled={advisorySubmitting}
                                    className="flex-1 bg-blue-600 hover:bg-blue-500 text-white font-bold py-2.5 rounded-lg transition-colors text-sm disabled:opacity-50 flex items-center justify-center space-x-2"
                                >
                                    <Plus size={16} />
                                    <span>{advisorySubmitting ? 'Publishing...' : 'Publish Advisory'}</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            <div className="space-y-4">
                {reports.map((report, idx) => (
                    <div
                        key={report.id}
                        className="glass-card rounded-2xl p-6 animate-slide-up"
                        style={{ animationDelay: `${idx * 100}ms` }}
                    >
                        <div className="flex justify-between items-start mb-4">
                            <div className="flex items-center space-x-3">
                                <div className={`p-2 rounded-lg ${report.source === 'official' || report.source === 'law_enforcement' ? 'bg-blue-900/50' : 'bg-navy-700'}`}>
                                    {report.source === 'official' || report.source === 'law_enforcement'
                                        ? <ShieldCheck size={20} className="text-blue-400" />
                                        : <AlertCircle size={20} className="text-accent-green" />
                                    }
                                </div>
                                <div>
                                    <div className="flex items-center space-x-2">
                                        <h3 className="font-bold text-lg leading-tight uppercase tracking-tight">{report.category}</h3>
                                        {(report.source === 'official' || report.source === 'law_enforcement') && (
                                            <span className="px-2 py-0.5 rounded text-[10px] font-bold uppercase bg-blue-500/20 text-blue-400 border border-blue-500/30">
                                                {report.source === 'law_enforcement' ? 'PDRM/CCID' : 'OFFICIAL'}
                                            </span>
                                        )}
                                    </div>
                                    <p className="text-xs text-slate-400">
                                        {report.source === 'official' || report.source === 'law_enforcement'
                                            ? <span className="text-blue-400 font-medium">{report.source === 'law_enforcement' ? 'Law Enforcement Advisory' : 'Official Advisory'}</span>
                                            : <>Reported by: <span className="text-slate-300 font-medium">{report.user?.fullName || report.user?.email}</span></>
                                        }
                                    </p>
                                </div>
                            </div>
                            <div className={`px-3 py-1 rounded-full text-xs font-bold uppercase flex items-center space-x-2 border ${report.status.toLowerCase() === 'pending' ? 'bg-yellow-400/10 text-yellow-400 border-yellow-400/20' :
                                report.status.toLowerCase() === 'verified' ? 'bg-accent-green/10 text-accent-green border-accent-green/20' :
                                    'bg-accent-red/10 text-accent-red border-accent-red/20'
                                }`}>
                                {getStatusIcon(report.status)}
                                <span>{report.status}</span>
                            </div>
                            {report.flagCount && report.flagCount > 0 ? (
                                <div className="ml-2 px-3 py-1 rounded-full text-xs font-bold uppercase bg-accent-red/20 text-accent-red border border-accent-red/30 flex items-center space-x-2">
                                    <AlertCircle size={14} />
                                    <span>{report.flagCount} Flags</span>
                                </div>
                            ) : null}
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
                                            <span className="text-sm font-mono text-white">{truncateId(report.target || '')}</span>
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
                                <button
                                    onClick={() => setSelectedReportId(report.id)}
                                    className="w-full bg-navy-900/50 hover:bg-navy-700 text-accent-green font-bold py-2 rounded-lg transition-colors text-sm border border-accent-green/30 flex items-center justify-center space-x-2"
                                >
                                    <Eye size={16} />
                                    <span>Deep Dive</span>
                                </button>
                            </div>
                        </div>
                    </div>
                ))}

                {selectedReportId && (
                    <ReportDetailModal
                        reportId={selectedReportId}
                        onClose={() => setSelectedReportId(null)}
                        onStatusUpdate={handleStatusUpdate}
                    />
                )}

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

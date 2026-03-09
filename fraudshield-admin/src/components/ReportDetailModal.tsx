import React, { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { X, Shield, MapPin, User } from 'lucide-react';

interface ReportDetailModalProps {
    reportId: string;
    onClose: () => void;
    onStatusUpdate: (id: string, status: string) => void;
}

const ReportDetailModal: React.FC<ReportDetailModalProps> = ({ reportId, onClose, onStatusUpdate }) => {
    const [report, setReport] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchDetail = async () => {
            try {
                const res = await adminService.getReportById(reportId);
                setReport(res.data);
            } catch (error) {
                console.error('Error fetching report detail:', error);
            } finally {
                setLoading(false);
            }
        };
        fetchDetail();
    }, [reportId]);

    if (loading) return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-navy-950/80 backdrop-blur-sm">
            <div className="text-white text-xl animate-pulse">Loading Report Details...</div>
        </div>
    );

    if (!report) return null;

    const getStatusStyles = (status: string) => {
        const s = status.toLowerCase();
        switch (s) {
            case 'pending': return 'bg-yellow-400/10 text-yellow-400 border-yellow-400/20';
            case 'verified': return 'bg-accent-green/10 text-accent-green border-accent-green/20';
            case 'rejected': return 'bg-accent-red/10 text-accent-red border-accent-red/20';
            default: return 'bg-slate-400/10 text-slate-400 border-slate-400/20';
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-navy-950/90 backdrop-blur-md p-4 overflow-y-auto">
            <div className="bg-navy-800 border border-navy-700 w-full max-w-4xl rounded-3xl overflow-hidden shadow-2xl animate-scale-up">
                {/* Header */}
                <div className="px-8 py-6 border-b border-navy-700 flex justify-between items-center bg-navy-900/50">
                    <div className="flex items-center space-x-4">
                        <div className="bg-accent-green/10 p-3 rounded-2xl">
                            <Shield className="text-accent-green" size={24} />
                        </div>
                        <div>
                            <h2 className="text-2xl font-bold text-white uppercase tracking-tight">{report.category}</h2>
                            <p className="text-slate-400 text-sm">Report ID: <span className="font-mono text-xs">{report.id}</span></p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-navy-700 rounded-full transition-colors">
                        <X size={24} className="text-slate-400" />
                    </button>
                </div>

                <div className="p-8 grid grid-cols-1 lg:grid-cols-3 gap-8">
                    {/* Left Column: Core Details */}
                    <div className="lg:col-span-2 space-y-8">
                        <div>
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3">Description</h4>
                            <div className="bg-navy-900/50 border border-navy-700 p-4 rounded-2xl text-slate-200 leading-relaxed italic">
                                "{report.description}"
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="bg-navy-900/30 p-4 rounded-2xl border border-navy-700/50">
                                <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-1">Target Type</h4>
                                <p className="text-white font-medium">{report.targetType || 'N/A'}</p>
                            </div>
                            <div className="bg-navy-900/30 p-4 rounded-2xl border border-navy-700/50">
                                <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-1">Target Value</h4>
                                <p className="text-white font-mono text-sm break-all">{report.target || 'N/A'}</p>
                            </div>
                        </div>

                        {/* Evidence Section */}
                        {report.evidence && Object.keys(report.evidence).length > 0 && (
                            <div>
                                <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3">Evidence Data</h4>
                                <div className="bg-navy-900/80 border border-navy-700 p-4 rounded-2xl overflow-x-auto">
                                    <pre className="text-xs text-accent-green font-mono">
                                        {JSON.stringify(report.evidence, null, 2)}
                                    </pre>
                                </div>
                            </div>
                        )}

                        {/* Location Section */}
                        {(report.latitude || report.longitude) && (
                            <div>
                                <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-3 flex items-center">
                                    <MapPin size={14} className="mr-1" /> Incident Location
                                </h4>
                                <div className="bg-navy-900/30 p-4 rounded-2xl border border-navy-700/50 flex items-center justify-between">
                                    <div>
                                        <p className="text-slate-300 text-sm">Lat: {report.latitude}, Long: {report.longitude}</p>
                                    </div>
                                    <a 
                                        href={`https://www.google.com/maps/search/?api=1&query=${report.latitude},${report.longitude}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="text-accent-green hover:underline text-sm font-bold"
                                    >
                                        View on Maps
                                    </a>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Right Column: Meta & Actions */}
                    <div className="space-y-6">
                        {/* Reporter Card */}
                        <div className="bg-navy-900/50 border border-navy-700 p-6 rounded-3xl">
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4 flex items-center">
                                <User size={14} className="mr-1" /> Reported By
                            </h4>
                            <div className="space-y-3">
                                <p className="text-white font-bold">{report.user?.fullName || 'Anonymous'}</p>
                                <p className="text-slate-400 text-sm truncate">{report.user?.email}</p>
                                <div className="pt-2">
                                    <span className="text-[10px] bg-navy-700 text-slate-300 px-2 py-1 rounded-md uppercase font-bold">
                                        Joined {report.user?.createdAt ? new Date(report.user.createdAt).toLocaleDateString() : 'N/A'}
                                    </span>
                                </div>
                            </div>
                        </div>

                        {/* Status Management */}
                        <div className="bg-navy-900/50 border border-navy-700 p-6 rounded-3xl">
                            <h4 className="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4">Current Status</h4>
                            <div className={`px-4 py-2 rounded-xl text-sm font-bold uppercase text-center border ${getStatusStyles(report.status)} mb-6`}>
                                {report.status}
                            </div>
                            
                            <div className="space-y-3">
                                {report.status.toLowerCase() !== 'verified' && (
                                    <button 
                                        onClick={() => onStatusUpdate(report.id, 'VERIFIED')}
                                        className="w-full bg-accent-green hover:bg-green-500 text-navy-900 font-bold py-3 rounded-xl transition-all shadow-lg shadow-accent-green/10"
                                    >
                                        Verify & Approve
                                    </button>
                                )}
                                {report.status.toLowerCase() !== 'rejected' && (
                                    <button 
                                        onClick={() => onStatusUpdate(report.id, 'REJECTED')}
                                        className="w-full bg-navy-700 hover:bg-accent-red/20 hover:text-accent-red text-slate-300 font-bold py-3 rounded-xl transition-all border border-navy-600"
                                    >
                                        Reject Report
                                    </button>
                                )}
                                {report.status.toLowerCase() !== 'pending' && (
                                    <button 
                                        onClick={() => onStatusUpdate(report.id, 'PENDING')}
                                        className="w-full bg-transparent hover:bg-navy-700 text-slate-400 font-bold py-2 rounded-xl transition-all"
                                    >
                                        Back to Pending
                                    </button>
                                )}
                            </div>
                        </div>

                        {/* Stats Summary */}
                        <div className="px-6 space-y-4">
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-500">Public Status:</span>
                                <span className={report.isPublic ? 'text-accent-green font-bold' : 'text-slate-400'}>
                                    {report.isPublic ? 'Visible' : 'Private'}
                                </span>
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-500">Comments:</span>
                                <span className="text-white font-bold">{report.comments?.length || 0}</span>
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-slate-500">Verifications:</span>
                                <span className="text-white font-bold">{report.verifications?.length || 0}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ReportDetailModal;

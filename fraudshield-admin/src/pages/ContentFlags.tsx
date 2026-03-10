import React, { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Flag, Trash2, CheckCircle, XCircle, User } from 'lucide-react';

const ContentFlags: React.FC = () => {
    const [flags, setFlags] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchFlags = async () => {
        try {
            const res = await adminService.getContentFlags();
            setFlags(res.data);
        } catch (error) {
            console.error('Error fetching flags:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchFlags();
    }, []);

    const handleUpdateStatus = async (id: string, status: string) => {
        try {
            await adminService.updateFlagStatus(id, status);
            fetchFlags();
        } catch (error) {
            console.error('Error updating flag status:', error);
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'PENDING': return 'text-yellow-400 bg-yellow-400/10 border-yellow-400/20';
            case 'TAKEN_ACTION': return 'text-accent-red bg-accent-red/10 border-accent-red/20';
            case 'DISMISSED': return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
            default: return 'text-slate-400';
        }
    };

    if (loading) return <div className="p-8 text-white">Loading flags...</div>;

    return (
        <div className="p-8 space-y-8 animate-fade-in">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-4xl font-black text-white uppercase tracking-tighter italic">
                        Content <span className="text-accent-green">Flags</span>
                    </h1>
                    <p className="text-slate-400 mt-2 font-medium">Community moderation reports and safety alerts.</p>
                </div>
                <div className="bg-navy-800 p-1 rounded-2xl border border-navy-700 flex">
                    <div className="px-6 py-2 bg-navy-700 text-white rounded-xl text-sm font-bold shadow-lg">
                        {flags.filter(f => f.status === 'PENDING').length} Pending
                    </div>
                </div>
            </div>

            <div className="bg-navy-800 border border-navy-700 rounded-3xl overflow-hidden shadow-2xl">
                <table className="w-full text-left truncate">
                    <thead className="bg-navy-900/50 border-b border-navy-700">
                        <tr>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Target</th>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Type</th>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Reporter</th>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Reason</th>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Status</th>
                            <th className="px-6 py-5 text-xs font-bold text-slate-500 uppercase tracking-widest">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-navy-700/50">
                        {flags.map((flag) => (
                            <tr key={flag.id} className="hover:bg-navy-700/30 transition-colors group">
                                <td className="px-6 py-5">
                                    <div className="text-white font-mono text-xs">{flag.targetId}</div>
                                </td>
                                <td className="px-6 py-5">
                                    <span className="px-3 py-1 bg-navy-700 text-slate-300 text-[10px] font-bold rounded-lg uppercase">
                                        {flag.type}
                                    </span>
                                </td>
                                <td className="px-6 py-5">
                                    <div className="flex items-center space-x-3">
                                        <div className="bg-navy-700 p-2 rounded-xl">
                                            <User size={14} className="text-slate-400" />
                                        </div>
                                        <div>
                                            <div className="text-sm font-bold text-slate-200">{flag.user?.fullName}</div>
                                            <div className="text-[10px] text-slate-500 font-medium truncate max-w-[120px]">{flag.user?.email}</div>
                                        </div>
                                    </div>
                                </td>
                                <td className="px-6 py-5">
                                    <div className="text-sm text-slate-300 font-medium">{flag.reason}</div>
                                </td>
                                <td className="px-6 py-5">
                                    <span className={`px-3 py-1 text-[10px] font-black rounded-lg border ${getStatusColor(flag.status)}`}>
                                        {flag.status}
                                    </span>
                                </td>
                                <td className="px-6 py-5">
                                    <div className="flex items-center space-x-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                        {flag.status === 'PENDING' && (
                                            <>
                                                <button 
                                                    onClick={() => handleUpdateStatus(flag.id, 'TAKEN_ACTION')}
                                                    className="p-2 bg-accent-red/10 text-accent-red hover:bg-accent-red/20 rounded-lg transition-colors"
                                                    title="Take Action"
                                                >
                                                    <Trash2 size={16} />
                                                </button>
                                                <button 
                                                    onClick={() => handleUpdateStatus(flag.id, 'DISMISSED')}
                                                    className="p-2 bg-accent-green/10 text-accent-green hover:bg-accent-green/20 rounded-lg transition-colors"
                                                    title="Dismiss"
                                                >
                                                    <CheckCircle size={16} />
                                                </button>
                                            </>
                                        )}
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {flags.length === 0 && (
                    <div className="p-20 text-center">
                        <div className="bg-navy-700/50 w-16 h-16 rounded-3xl flex items-center justify-center mx-auto mb-4 border border-navy-600">
                            <Flag className="text-slate-500" size={32} />
                        </div>
                        <h3 className="text-white font-bold text-lg italic uppercase">No flags found</h3>
                        <p className="text-slate-500 text-sm mt-1">Excellent job! The community feed is currently clean.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default ContentFlags;

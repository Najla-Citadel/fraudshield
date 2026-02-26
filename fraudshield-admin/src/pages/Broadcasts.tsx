import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Radio, AlertTriangle, Info, ShieldAlert, Send } from 'lucide-react';

interface Broadcast {
    id: string;
    title: string;
    message: string;
    type: string;
    createdAt: string;
    recipientCount: number;
}

const Broadcasts = () => {
    const [broadcasts, setBroadcasts] = useState<Broadcast[]>([]);
    const [loading, setLoading] = useState(true);
    const [isCreating, setIsCreating] = useState(false);

    // Form State
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');

    const fetchBroadcasts = async () => {
        try {
            const response = await adminService.getBroadcasts();
            setBroadcasts(response.data);
        } catch (error) {
            console.error('Error fetching broadcasts:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBroadcasts();
    }, []);

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!window.confirm('Are you sure you want to broadcast this message to ALL users? This action cannot be undone.')) {
            return;
        }

        const payload = { title, message };

        try {
            await adminService.createBroadcast(payload);
            fetchBroadcasts();
            setIsCreating(false);
            setTitle('');
            setMessage('');
            alert('Broadcast sent successfully.');
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to send broadcast');
        }
    };

    if (loading) return <div className="text-white">Loading...</div>;

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold flex items-center gap-3">
                        <Radio className="text-accent-green" size={32} />
                        Threat Intelligence Broadcaster
                    </h2>
                    <p className="text-slate-400 mt-2">Push critical scam warnings and platform updates to all users</p>
                </div>
                {!isCreating && (
                    <button
                        onClick={() => setIsCreating(true)}
                        className="bg-accent-red hover:bg-red-500 text-white font-bold py-2 px-4 rounded-lg flex items-center space-x-2 transition-colors shadow-[0_0_15px_rgba(239,68,68,0.3)] hover:shadow-[0_0_20px_rgba(239,68,68,0.5)]"
                    >
                        <AlertTriangle size={18} />
                        <span>New Broadcast Alert</span>
                    </button>
                )}
            </header>

            {isCreating && (
                <div className="glass-card p-6 rounded-2xl mb-8 animate-slide-up border-accent-red/30">
                    <div className="flex items-center gap-3 mb-6 bg-accent-red/10 p-4 rounded-xl border border-accent-red/20">
                        <ShieldAlert className="text-accent-red" size={24} />
                        <div>
                            <h3 className="text-lg font-bold text-white">System-Wide Alert</h3>
                            <p className="text-sm text-slate-300">This message will be pushed securely to all active user accounts.</p>
                        </div>
                    </div>

                    <form onSubmit={handleSend} className="space-y-4">
                        <div>
                            <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Alert Title</label>
                            <input
                                type="text"
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                                placeholder="e.g. URGENT: New Phishing Scam Targeting Maybank Users"
                                maxLength={100}
                                className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-red outline-none"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Detailed Message</label>
                            <textarea
                                value={message}
                                onChange={(e) => setMessage(e.target.value)}
                                rows={5}
                                placeholder="Provide actionable intelligence on how users can protect themselves..."
                                className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-red outline-none"
                                required
                            />
                        </div>

                        <div className="flex space-x-3 pt-4 border-t border-navy-700/50">
                            <button
                                type="submit"
                                className="bg-accent-red text-white font-bold py-2 px-6 rounded-lg hover:bg-red-500 transition-colors flex items-center gap-2"
                            >
                                <Send size={16} />
                                <span>Broadcast Now</span>
                            </button>
                            <button
                                type="button"
                                onClick={() => setIsCreating(false)}
                                className="bg-navy-700 border border-navy-600 text-white font-bold py-2 px-6 rounded-lg hover:bg-navy-600 transition-colors"
                            >
                                Cancel
                            </button>
                        </div>
                    </form>
                </div>
            )}

            <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                <Info size={20} className="text-slate-400" />
                Broadcast History
            </h3>

            <div className="space-y-4">
                {broadcasts.map((broadcast, idx) => (
                    <div
                        key={broadcast.id}
                        className="glass-card p-6 rounded-xl animate-fade-in flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-navy-800/50 transition-colors"
                        style={{ animationDelay: `${idx * 100}ms` }}
                    >
                        <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2">
                                <span className="bg-accent-red/20 text-accent-red text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded border border-accent-red/30">
                                    Broadcast
                                </span>
                                <h4 className="text-lg font-bold text-white leading-tight">{broadcast.title}</h4>
                            </div>
                            <p className="text-slate-400 text-sm">{broadcast.message}</p>
                        </div>

                        <div className="flex items-center gap-8 md:border-l border-navy-700/50 md:pl-6">
                            <div className="flex flex-col">
                                <span className="text-[10px] uppercase text-slate-500 font-bold tracking-wider mb-1">Recipients</span>
                                <span className="text-xl font-black text-white">{broadcast.recipientCount.toLocaleString()}</span>
                            </div>
                            <div className="flex flex-col text-right">
                                <span className="text-[10px] uppercase text-slate-500 font-bold tracking-wider mb-1">Sent Date</span>
                                <span className="text-sm font-medium text-slate-300">
                                    {new Date(broadcast.createdAt).toLocaleDateString()}<br />
                                    <span className="text-xs text-slate-500">{new Date(broadcast.createdAt).toLocaleTimeString()}</span>
                                </span>
                            </div>
                        </div>
                    </div>
                ))}

                {broadcasts.length === 0 && !loading && (
                    <div className="text-center py-24 bg-navy-800/30 border-2 border-dashed border-navy-700 rounded-xl">
                        <Radio size={48} className="mx-auto text-slate-600 mb-4" />
                        <h3 className="text-xl font-bold text-slate-400">No broadcasts sent</h3>
                        <p className="text-slate-500 mt-2">Threat intelligence broadcasts will appear here.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Broadcasts;

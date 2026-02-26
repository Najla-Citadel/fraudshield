import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Search, ShieldAlert, Tag, Trash2, CheckCircle2, AlertTriangle, Fingerprint, Crosshair, HelpCircle } from 'lucide-react';

interface Transaction {
    id: string;
    checkType: string;
    target: string;
    riskScore: number;
    status: string;
    amount: number;
    merchant: string;
    paymentMethod: string;
    platform: string;
    createdAt: string;
    user: { fullName: string; email: string };
    metadata: any;
}

interface FraudLabel {
    id: string;
    txId: string;
    label: string;
    labeledBy: string;
    createdAt: string;
}

const FraudAnalysis = () => {
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [labels, setLabels] = useState<FraudLabel[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'logs' | 'labels'>('logs');

    // Label Form State
    const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);
    const [labelName, setLabelName] = useState('');

    const fetchData = async () => {
        setLoading(true);
        try {
            const [txRes, labelsRes] = await Promise.all([
                adminService.getTransactions(),
                adminService.getFraudLabels()
            ]);
            setTransactions(txRes.data);
            setLabels(labelsRes.data);
        } catch (error) {
            console.error('Error fetching fraud analysis data:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleCreateLabel = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedTx) return;

        try {
            await adminService.createFraudLabel({
                txId: selectedTx.id,
                label: labelName
            });
            fetchData();
            setSelectedTx(null);
            setLabelName('');
            alert('Fraud label applied successfully.');
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to apply label');
        }
    };

    const handleDeleteLabel = async (id: string) => {
        if (!window.confirm('Remove this fraud label?')) return;
        try {
            await adminService.deleteFraudLabel(id);
            setLabels(labels.filter(l => l.id !== id));
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to delete label');
        }
    };

    if (loading) return <div className="text-white">Loading...</div>;

    const getRiskColor = (score: number) => {
        if (score >= 80) return 'text-accent-red';
        if (score >= 50) return 'text-yellow-400';
        return 'text-accent-green';
    };

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold flex items-center gap-3">
                        <Search className="text-accent-green" size={32} />
                        Fraud Analysis & Labeling
                    </h2>
                    <p className="text-slate-400 mt-2">Investigate suspicious transactions and apply global fraud labels.</p>
                </div>

                <div className="flex bg-navy-900/50 p-1 rounded-xl border border-navy-700/50 backdrop-blur-md">
                    <button
                        onClick={() => setActiveTab('logs')}
                        className={`px-4 py-2 rounded-lg font-bold text-sm transition-colors flex items-center space-x-2 ${activeTab === 'logs' ? 'bg-accent-green text-navy-900' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        <ShieldAlert size={16} />
                        <span>Suspicious Logs</span>
                    </button>
                    <button
                        onClick={() => setActiveTab('labels')}
                        className={`px-4 py-2 rounded-lg font-bold text-sm transition-colors flex items-center space-x-2 ${activeTab === 'labels' ? 'bg-accent-green text-navy-900' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        <Tag size={16} />
                        <span>Active Labels</span>
                    </button>
                </div>
            </header>

            {activeTab === 'logs' && (
                <div className="animate-fade-in grid grid-cols-1 xl:grid-cols-3 gap-6">
                    {/* Log Table */}
                    <div className="xl:col-span-2 glass-card overflow-hidden">
                        <div className="p-4 border-b border-navy-700/50 bg-navy-900/50 flex justify-between items-center">
                            <h3 className="text-lg font-bold text-white flex items-center gap-2">
                                <AlertTriangle className="text-yellow-400" size={18} />
                                High-Risk Transactions
                            </h3>
                            <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">{transactions.length} Records</span>
                        </div>
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="border-b border-navy-700 bg-navy-800/30">
                                        <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Target / ID</th>
                                        <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Type</th>
                                        <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Score</th>
                                        <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">User</th>
                                        <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Date</th>
                                        <th className="p-4"></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {transactions.map(tx => (
                                        <tr
                                            key={tx.id}
                                            onClick={() => setSelectedTx(tx)}
                                            className={`border-b border-navy-700/50 hover:bg-navy-700/20 transition-colors cursor-pointer ${selectedTx?.id === tx.id ? 'bg-navy-700/40' : ''}`}
                                        >
                                            <td className="p-4">
                                                <div className="font-bold text-white mb-0.5">{tx.target || tx.merchant || 'Unknown Target'}</div>
                                                <div className="text-[10px] text-slate-500 font-mono break-all">{tx.id}</div>
                                            </td>
                                            <td className="p-4">
                                                <span className="text-[10px] uppercase font-bold tracking-wider text-slate-300 bg-navy-900/50 px-2 py-1 rounded">
                                                    {tx.checkType}
                                                </span>
                                            </td>
                                            <td className="p-4 font-black">
                                                <span className={getRiskColor(tx.riskScore)}>{tx.riskScore}</span>
                                            </td>
                                            <td className="p-4 text-sm">
                                                <div className="text-white">{tx.user?.fullName || 'Anonymous'}</div>
                                            </td>
                                            <td className="p-4 text-xs text-slate-400">
                                                {new Date(tx.createdAt).toLocaleDateString()}
                                            </td>
                                            <td className="p-4 text-right">
                                                <button className="text-accent-green hover:text-white transition-colors">
                                                    <Tag size={16} />
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                    {transactions.length === 0 && (
                                        <tr>
                                            <td colSpan={6} className="p-8 text-center text-slate-500 font-medium">
                                                No high-risk transactions detected.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>

                    {/* Investigation Panel */}
                    <div className="xl:col-span-1">
                        {selectedTx ? (
                            <div className="glass-card p-6 rounded-2xl sticky top-6 animate-slide-up">
                                <h3 className="text-xl font-bold text-white border-b border-navy-700/50 pb-4 mb-4 flex items-center gap-2">
                                    <Crosshair size={20} className="text-accent-red" />
                                    Investigate Target
                                </h3>

                                <div className="space-y-4 mb-6">
                                    <div>
                                        <label className="text-[10px] uppercase text-slate-500 font-bold tracking-wider mb-1 block">Primary Target</label>
                                        <div className="text-lg font-bold text-white bg-navy-900/50 p-3 rounded-lg border border-navy-700">
                                            {selectedTx.target || selectedTx.merchant || 'Unknown'}
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="bg-navy-900/30 p-3 rounded-lg border border-navy-700/50">
                                            <label className="text-[10px] uppercase text-slate-500 font-bold tracking-wider mb-1 block">Risk Score</label>
                                            <div className={`text-2xl font-black ${getRiskColor(selectedTx.riskScore)}`}>
                                                {selectedTx.riskScore}/100
                                            </div>
                                        </div>
                                        <div className="bg-navy-900/30 p-3 rounded-lg border border-navy-700/50">
                                            <label className="text-[10px] uppercase text-slate-500 font-bold tracking-wider mb-1 block">Context</label>
                                            <div className="text-sm font-bold text-white uppercase mt-1">
                                                {selectedTx.checkType}
                                            </div>
                                        </div>
                                    </div>

                                    {(selectedTx.amount || selectedTx.platform) && (
                                        <div className="bg-navy-900/30 p-4 rounded-lg border border-navy-700/50 space-y-2">
                                            {selectedTx.amount && (
                                                <div className="flex justify-between text-sm">
                                                    <span className="text-slate-400">Amount:</span>
                                                    <span className="text-white font-bold">RM {selectedTx.amount.toFixed(2)}</span>
                                                </div>
                                            )}
                                            {selectedTx.platform && (
                                                <div className="flex justify-between text-sm">
                                                    <span className="text-slate-400">Platform:</span>
                                                    <span className="text-white font-bold">{selectedTx.platform}</span>
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>

                                <form onSubmit={handleCreateLabel} className="bg-accent-red/5 p-4 rounded-xl border border-accent-red/20">
                                    <h4 className="font-bold text-white mb-2 flex items-center gap-2 text-sm">
                                        <Fingerprint size={14} className="text-accent-red" />
                                        Apply Global Fraud Label
                                    </h4>
                                    <p className="text-xs text-slate-400 mb-4">
                                        Marking this target will automatically block it for all users going forward.
                                    </p>

                                    <div className="mb-4">
                                        <input
                                            type="text"
                                            value={labelName}
                                            onChange={(e) => setLabelName(e.target.value)}
                                            placeholder="Label Name (e.g. KNOWN_PHISHING_URL)"
                                            className="w-full bg-navy-900 border border-navy-700 rounded-lg p-2.5 text-sm text-white focus:border-accent-red outline-none uppercase"
                                            required
                                        />
                                    </div>
                                    <button
                                        type="submit"
                                        className="w-full bg-accent-red hover:bg-red-500 text-white font-bold py-2.5 rounded-lg transition-colors flex items-center justify-center gap-2 text-sm"
                                    >
                                        <Tag size={16} />
                                        Label as Fraudulent
                                    </button>
                                </form>
                            </div>
                        ) : (
                            <div className="glass-card p-10 rounded-2xl flex flex-col items-center justify-center text-center h-full border-dashed border-2 border-navy-600/50">
                                <HelpCircle size={48} className="text-slate-600 mb-4" />
                                <h3 className="text-lg font-bold text-slate-300">No Target Selected</h3>
                                <p className="text-sm text-slate-500 mt-2">Select a high-risk transaction from the log to view details and apply global tags.</p>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {activeTab === 'labels' && (
                <div className="animate-fade-in">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {labels.map((label, idx) => (
                            <div
                                key={label.id}
                                className="glass-card p-6 rounded-2xl animate-slide-up relative group border border-accent-red/20 hover:border-accent-red/50 transition-colors"
                                style={{ animationDelay: `${idx * 50}ms` }}
                            >
                                <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity flex space-x-2 z-10">
                                    <button
                                        onClick={() => handleDeleteLabel(label.id)}
                                        className="bg-navy-900/90 p-1.5 rounded-md text-slate-400 hover:text-accent-red backdrop-blur-sm"
                                        title="Remove Label"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>

                                <div className="flex items-center gap-3 mb-4">
                                    <div className="bg-accent-red/20 p-2 rounded-lg">
                                        <Fingerprint className="text-accent-red" size={20} />
                                    </div>
                                    <h3 className="font-bold text-white text-lg truncate" title={label.label}>{label.label}</h3>
                                </div>

                                <div className="space-y-3 bg-navy-900/40 p-3 rounded-lg">
                                    <div>
                                        <span className="text-[10px] uppercase text-slate-500 font-bold block mb-0.5">Origin TX ID</span>
                                        <span className="text-xs text-slate-300 font-mono break-all">{label.txId}</span>
                                    </div>
                                    <div>
                                        <span className="text-[10px] uppercase text-slate-500 font-bold block mb-0.5">Labeled By</span>
                                        <span className="text-sm text-white font-medium">{label.labeledBy}</span>
                                    </div>
                                    <div>
                                        <span className="text-[10px] uppercase text-slate-500 font-bold block mb-0.5">Date Applied</span>
                                        <span className="text-sm text-slate-400">{new Date(label.createdAt).toLocaleString()}</span>
                                    </div>
                                </div>

                                <div className="mt-4 flex items-center gap-1 text-[10px] uppercase font-bold text-accent-red tracking-wider justify-center bg-accent-red/10 py-1.5 rounded">
                                    <CheckCircle2 size={12} /> Target Blocked
                                </div>
                            </div>
                        ))}

                        {labels.length === 0 && !loading && (
                            <div className="col-span-full text-center py-24 bg-navy-800/30 border-2 border-dashed border-navy-700 rounded-2xl">
                                <ShieldAlert size={48} className="mx-auto text-slate-600 mb-4" />
                                <h3 className="text-xl font-bold text-slate-400">No Active Fraud Labels</h3>
                                <p className="text-slate-500 mt-2">Investigate suspicious logs to apply systemic blocks to known fraudulent entities.</p>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default FraudAnalysis;

import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { ShoppingBag, Edit2, Trash2, Plus, CheckCircle2, Gift, RefreshCw } from 'lucide-react';

interface Reward {
    id: string;
    name: string;
    description: string;
    pointsCost: number;
    type: string;
    metadata: any;
    active: boolean;
}

interface Redemption {
    id: string;
    status: string;
    createdAt: string;
    user: { fullName: string; email: string };
    reward: { name: string; type: string };
}

const Rewards = () => {
    const [rewards, setRewards] = useState<Reward[]>([]);
    const [redemptions, setRedemptions] = useState<Redemption[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'catalog' | 'redemptions'>('catalog');

    // Reward Form State
    const [isEditing, setIsEditing] = useState<Reward | null>(null);
    const [isCreating, setIsCreating] = useState(false);
    const [name, setName] = useState('');
    const [description, setDescription] = useState('');
    const [pointsCost, setPointsCost] = useState<string | number>('');
    const [type, setType] = useState('digital');
    const [active, setActive] = useState(true);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [rewardsRes, redemptionsRes] = await Promise.all([
                adminService.getRewards(),
                adminService.getRedemptions()
            ]);
            setRewards(rewardsRes.data);
            setRedemptions(redemptionsRes.data);
        } catch (error) {
            console.error('Error fetching store data:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleSaveReward = async (e: React.FormEvent) => {
        e.preventDefault();
        const payload = {
            name,
            description,
            pointsCost: Number(pointsCost),
            type,
            active,
            metadata: {}
        };

        try {
            if (isEditing) {
                await adminService.updateReward(isEditing.id, payload);
            } else {
                await adminService.createReward(payload);
            }
            fetchData();
            resetForm();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to save reward');
        }
    };

    const handleDeleteReward = async (id: string) => {
        if (!window.confirm('Delete this reward from the catalog?')) return;
        try {
            await adminService.deleteReward(id);
            setRewards(rewards.filter(r => r.id !== id));
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to delete reward');
        }
    };

    const handleUpdateRedemption = async (id: string, status: string) => {
        try {
            await adminService.updateRedemptionStatus(id, status);
            fetchData();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to update redemption status');
        }
    };

    const resetForm = () => {
        setIsEditing(null);
        setIsCreating(false);
        setName('');
        setDescription('');
        setPointsCost('');
        setType('digital');
        setActive(true);
    };

    const startEdit = (reward: Reward) => {
        setIsEditing(reward);
        setName(reward.name);
        setDescription(reward.description);
        setPointsCost(reward.pointsCost);
        setType(reward.type);
        setActive(reward.active);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    if (loading) return <div className="text-white">Loading...</div>;

    const getStatusColor = (status: string) => {
        switch (status.toLowerCase()) {
            case 'completed': return 'text-accent-green bg-accent-green/10 border-accent-green/30';
            case 'pending': return 'text-yellow-400 bg-yellow-400/10 border-yellow-400/30';
            case 'rejected': return 'text-accent-red bg-accent-red/10 border-accent-red/30';
            default: return 'text-slate-400 bg-slate-400/10 border-slate-400/30';
        }
    };

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold">Store & Rewards</h2>
                    <p className="text-slate-400">Manage reward catalog and user redemptions</p>
                </div>

                <div className="flex bg-navy-900/50 p-1 rounded-xl border border-navy-700/50 backdrop-blur-md">
                    <button
                        onClick={() => setActiveTab('catalog')}
                        className={`px-4 py-2 rounded-lg font-bold text-sm transition-colors flex items-center space-x-2 ${activeTab === 'catalog' ? 'bg-accent-green text-navy-900' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        <ShoppingBag size={16} />
                        <span>Catalog</span>
                    </button>
                    <button
                        onClick={() => setActiveTab('redemptions')}
                        className={`px-4 py-2 rounded-lg font-bold text-sm transition-colors flex items-center space-x-2 ${activeTab === 'redemptions' ? 'bg-accent-green text-navy-900' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        <Gift size={16} />
                        <span>Redemptions
                            {redemptions.filter(r => r.status === 'pending').length > 0 &&
                                <span className="ml-2 bg-accent-red text-white text-[10px] px-1.5 py-0.5 rounded-full">
                                    {redemptions.filter(r => r.status === 'pending').length}
                                </span>
                            }
                        </span>
                    </button>
                </div>
            </header>

            {activeTab === 'catalog' && (
                <div className="animate-fade-in">
                    <div className="mb-6 flex justify-end">
                        {!isCreating && !isEditing && (
                            <button
                                onClick={() => setIsCreating(true)}
                                className="bg-accent-green hover:bg-green-500 text-navy-900 font-bold py-2 px-4 rounded-lg flex items-center space-x-2 transition-colors"
                            >
                                <Plus size={18} />
                                <span>Add Reward</span>
                            </button>
                        )}
                    </div>

                    {(isCreating || isEditing) && (
                        <div className="glass-card p-6 rounded-2xl mb-8 animate-slide-up">
                            <h3 className="text-xl font-bold text-white mb-4">
                                {isEditing ? 'Edit Reward Item' : 'Add New Reward'}
                            </h3>
                            <form onSubmit={handleSaveReward} className="space-y-4">
                                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                                    <div className="md:col-span-2">
                                        <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Item Name</label>
                                        <input
                                            type="text"
                                            value={name}
                                            onChange={(e) => setName(e.target.value)}
                                            className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Points Cost</label>
                                        <input
                                            type="number"
                                            value={pointsCost}
                                            onChange={(e) => setPointsCost(e.target.value)}
                                            className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Item Type</label>
                                        <select
                                            value={type}
                                            onChange={(e) => setType(e.target.value)}
                                            className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none appearance-none"
                                        >
                                            <option value="digital">Digital Code/Voucher</option>
                                            <option value="physical">Physical Item</option>
                                            <option value="account">Account Benefit</option>
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Description</label>
                                    <textarea
                                        value={description}
                                        onChange={(e) => setDescription(e.target.value)}
                                        rows={3}
                                        className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                        required
                                    />
                                </div>

                                <div className="flex items-center space-x-2">
                                    <input
                                        type="checkbox"
                                        id="active"
                                        checked={active}
                                        onChange={(e) => setActive(e.target.checked)}
                                        className="w-4 h-4 text-accent-green bg-navy-900 border-navy-700 rounded focus:ring-accent-green accent-accent-green"
                                    />
                                    <label htmlFor="active" className="text-sm text-slate-300">Item is active and available in store</label>
                                </div>

                                <div className="flex space-x-3 pt-4 border-t border-navy-700/50">
                                    <button
                                        type="submit"
                                        className="bg-accent-green text-navy-900 font-bold py-2 px-6 rounded-lg hover:bg-green-500 transition-colors"
                                    >
                                        Save Reward
                                    </button>
                                    <button
                                        type="button"
                                        onClick={resetForm}
                                        className="bg-navy-700 border border-navy-600 text-white font-bold py-2 px-6 rounded-lg hover:bg-navy-600 transition-colors"
                                    >
                                        Cancel
                                    </button>
                                </div>
                            </form>
                        </div>
                    )}

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {rewards.map((reward, idx) => (
                            <div
                                key={reward.id}
                                className={`glass-card p-6 rounded-2xl animate-slide-up relative group border ${reward.active ? 'border-navy-600/50' : 'border-red-500/30 opacity-75'}`}
                                style={{ animationDelay: `${idx * 50}ms` }}
                            >
                                <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity flex space-x-2 z-10">
                                    <button
                                        onClick={() => startEdit(reward)}
                                        className="bg-navy-700/80 p-1.5 rounded-md text-slate-300 hover:text-white backdrop-blur-sm"
                                    >
                                        <Edit2 size={16} />
                                    </button>
                                    <button
                                        onClick={() => handleDeleteReward(reward.id)}
                                        className="bg-navy-700/80 p-1.5 rounded-md text-slate-300 hover:text-accent-red backdrop-blur-sm"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </div>

                                {!reward.active && (
                                    <div className="absolute top-4 left-4 bg-red-500/20 text-red-400 text-[10px] uppercase font-bold px-2 py-0.5 rounded border border-red-500/30">
                                        Inactive
                                    </div>
                                )}

                                <div className="flex flex-col items-center justify-center py-6 mb-2">
                                    <div className="w-20 h-20 bg-navy-800/80 rounded-full flex items-center justify-center mb-4 border border-navy-700 shadow-inner">
                                        <Gift size={32} className={reward.active ? "text-accent-green" : "text-slate-500"} />
                                    </div>
                                    <h3 className="text-xl font-bold text-white text-center leading-tight mb-1">{reward.name}</h3>
                                    <div className="text-slate-400 text-xs uppercase tracking-wider font-semibold">{reward.type}</div>
                                </div>

                                <div className="bg-navy-900/60 rounded-xl p-4 border border-navy-700/50 text-center">
                                    <div className="text-2xl font-black text-accent-green mb-1">{reward.pointsCost} <span className="text-sm font-bold text-slate-400">pts</span></div>
                                </div>
                            </div>
                        ))}

                        {rewards.length === 0 && !loading && (
                            <div className="col-span-full text-center py-20 bg-navy-800/50 border-2 border-dashed border-navy-700 rounded-2xl">
                                <ShoppingBag size={48} className="mx-auto text-slate-600 mb-4" />
                                <h3 className="text-xl font-bold text-slate-400">Store is empty</h3>
                                <p className="text-slate-500 mt-2">Add rewards to your catalog so users can redeem their protection points.</p>
                            </div>
                        )}
                    </div>
                </div>
            )}

            {activeTab === 'redemptions' && (
                <div className="glass-card overflow-hidden animate-fade-in">
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse">
                            <thead>
                                <tr className="border-b border-navy-700 bg-navy-900/50">
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Date</th>
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">User</th>
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Reward Item</th>
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Type</th>
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Status</th>
                                    <th className="p-4 text-xs font-bold text-slate-400 uppercase tracking-wider">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {redemptions.map((redemption) => (
                                    <tr key={redemption.id} className="border-b border-navy-700/50 hover:bg-navy-700/20 transition-colors">
                                        <td className="p-4 text-sm text-slate-300">
                                            {new Date(redemption.createdAt).toLocaleDateString()}
                                        </td>
                                        <td className="p-4">
                                            <div className="font-medium text-white">{redemption.user.fullName || 'Unknown User'}</div>
                                            <div className="text-xs text-slate-400">{redemption.user.email}</div>
                                        </td>
                                        <td className="p-4 text-sm font-medium text-white">{redemption.reward.name}</td>
                                        <td className="p-4">
                                            <span className="text-xs text-slate-400 uppercase tracking-wider bg-navy-900/60 px-2 py-1 rounded inline-block">
                                                {redemption.reward.type}
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            <span className={`inline-flex items-center space-x-1 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border ${getStatusColor(redemption.status)}`}>
                                                {redemption.status === 'completed' && <CheckCircle2 size={12} />}
                                                {redemption.status === 'pending' && <RefreshCw size={12} />}
                                                <span>{redemption.status}</span>
                                            </span>
                                        </td>
                                        <td className="p-4">
                                            {redemption.status === 'pending' ? (
                                                <div className="flex space-x-2">
                                                    <button
                                                        onClick={() => handleUpdateRedemption(redemption.id, 'completed')}
                                                        className="px-3 py-1 bg-accent-green/20 text-accent-green hover:bg-accent-green hover:text-navy-900 rounded text-xs font-bold transition-colors"
                                                    >
                                                        Approve
                                                    </button>
                                                    <button
                                                        onClick={() => handleUpdateRedemption(redemption.id, 'rejected')}
                                                        className="px-3 py-1 bg-accent-red/20 text-accent-red hover:bg-accent-red hover:text-white rounded text-xs font-bold transition-colors"
                                                    >
                                                        Reject
                                                    </button>
                                                </div>
                                            ) : (
                                                <span className="text-xs text-slate-500 italic">Processed</span>
                                            )}
                                        </td>
                                    </tr>
                                ))}
                                {redemptions.length === 0 && (
                                    <tr>
                                        <td colSpan={6} className="p-8 text-center text-slate-500">
                                            No redemptions found in the system.
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Rewards;

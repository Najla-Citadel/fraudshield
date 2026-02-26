import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Award, Edit2, Trash2, Plus } from 'lucide-react';

interface BadgeDefinition {
    id: string;
    key: string;
    name: string;
    description: string;
    icon: string;
    tier: string;
    trigger: string;
    threshold: number | null;
}

const Badges = () => {
    const [badges, setBadges] = useState<BadgeDefinition[]>([]);
    const [loading, setLoading] = useState(true);
    const [isEditing, setIsEditing] = useState<BadgeDefinition | null>(null);
    const [isCreating, setIsCreating] = useState(false);

    // Form State
    const [key, setKey] = useState('');
    const [name, setName] = useState('');
    const [description, setDescription] = useState('');
    const [icon, setIcon] = useState('');
    const [tier, setTier] = useState('bronze');
    const [trigger, setTrigger] = useState('reputation');
    const [threshold, setThreshold] = useState<string | number>('');

    const fetchBadges = async () => {
        try {
            const response = await adminService.getBadges();
            setBadges(response.data);
        } catch (error) {
            console.error('Error fetching badges:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBadges();
    }, []);

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();

        const payload = {
            key,
            name,
            description,
            icon,
            tier,
            trigger,
            threshold: threshold ? Number(threshold) : null,
        };

        try {
            if (isEditing) {
                await adminService.updateBadge(isEditing.id, payload);
            } else {
                await adminService.createBadge(payload);
            }
            fetchBadges();
            resetForm();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to save badge');
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm('Are you sure you want to delete this badge?')) return;
        try {
            await adminService.deleteBadge(id);
            setBadges(badges.filter(b => b.id !== id));
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to delete badge');
        }
    };

    const resetForm = () => {
        setIsEditing(null);
        setIsCreating(false);
        setKey('');
        setName('');
        setDescription('');
        setIcon('');
        setTier('bronze');
        setTrigger('reputation');
        setThreshold('');
    };

    const startEdit = (badge: BadgeDefinition) => {
        setIsEditing(badge);
        setKey(badge.key);
        setName(badge.name);
        setDescription(badge.description);
        setIcon(badge.icon);
        setTier(badge.tier);
        setTrigger(badge.trigger);
        setThreshold(badge.threshold || '');
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    if (loading) return <div className="text-white">Loading...</div>;

    const getTierColor = (t: string) => {
        switch (t) {
            case 'platinum': return 'text-cyan-400 bg-cyan-400/10 border-cyan-400/30';
            case 'gold': return 'text-yellow-400 bg-yellow-400/10 border-yellow-400/30';
            case 'silver': return 'text-slate-300 bg-slate-300/10 border-slate-300/30';
            case 'bronze': default: return 'text-orange-400 bg-orange-400/10 border-orange-400/30';
        }
    };

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold">Gamification & Badges</h2>
                    <p className="text-slate-400">Configure system achievements and unlock triggers</p>
                </div>
                {!isCreating && !isEditing && (
                    <button
                        onClick={() => setIsCreating(true)}
                        className="bg-accent-green hover:bg-green-500 text-navy-900 font-bold py-2 px-4 rounded-lg flex items-center space-x-2 transition-colors"
                    >
                        <Plus size={18} />
                        <span>Create Badge</span>
                    </button>
                )}
            </header>

            {(isCreating || isEditing) && (
                <div className="glass-card p-6 rounded-2xl mb-8 animate-slide-up">
                    <h3 className="text-xl font-bold text-white mb-4">
                        {isEditing ? 'Edit Badge Definition' : 'Create New Badge'}
                    </h3>
                    <form onSubmit={handleSave} className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Internal Key</label>
                                <input
                                    type="text"
                                    value={key}
                                    onChange={(e) => setKey(e.target.value)}
                                    placeholder="e.g. elite_sentinel"
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Display Name</label>
                                <input
                                    type="text"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Icon (Emoji/Name)</label>
                                <input
                                    type="text"
                                    value={icon}
                                    onChange={(e) => setIcon(e.target.value)}
                                    placeholder="e.g. 🛡️"
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Tier</label>
                                <select
                                    value={tier}
                                    onChange={(e) => setTier(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none appearance-none"
                                >
                                    <option value="bronze">Bronze</option>
                                    <option value="silver">Silver</option>
                                    <option value="gold">Gold</option>
                                    <option value="platinum">Platinum</option>
                                </select>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div className="md:col-span-2">
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Description</label>
                                <input
                                    type="text"
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Trigger Metric</label>
                                <select
                                    value={trigger}
                                    onChange={(e) => setTrigger(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none appearance-none"
                                >
                                    <option value="reputation">Reputation</option>
                                    <option value="reports">Total Reports</option>
                                    <option value="streak">Login Streak</option>
                                    <option value="purchase">Store Purchase</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Trigger Threshold</label>
                                <input
                                    type="number"
                                    value={threshold}
                                    onChange={(e) => setThreshold(e.target.value)}
                                    placeholder="Leave empty if manual"
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                />
                            </div>
                        </div>

                        <div className="flex space-x-3 pt-4 border-t border-navy-700/50">
                            <button
                                type="submit"
                                className="bg-accent-green text-navy-900 font-bold py-2 px-6 rounded-lg hover:bg-green-500 transition-colors"
                            >
                                Save Badge
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
                {badges.map((badge, idx) => (
                    <div
                        key={badge.id}
                        className="glass-card p-6 rounded-2xl animate-slide-up relative overflow-hidden group"
                        style={{ animationDelay: `${idx * 50}ms` }}
                    >
                        <div className="absolute top-0 right-0 p-4 opacity-0 group-hover:opacity-100 transition-opacity flex space-x-2">
                            <button
                                onClick={() => startEdit(badge)}
                                className="bg-navy-700/80 p-1.5 rounded-md text-slate-300 hover:text-white backdrop-blur-sm"
                            >
                                <Edit2 size={16} />
                            </button>
                            <button
                                onClick={() => handleDelete(badge.id)}
                                className="bg-navy-700/80 p-1.5 rounded-md text-slate-300 hover:text-accent-red backdrop-blur-sm"
                            >
                                <Trash2 size={16} />
                            </button>
                        </div>

                        <div className="flex items-center space-x-4 mb-4">
                            <div className={`text-4xl w-16 h-16 rounded-xl flex items-center justify-center border ${getTierColor(badge.tier)}`}>
                                {badge.icon}
                            </div>
                            <div>
                                <h3 className="text-lg font-bold text-white leading-tight mb-1">{badge.name}</h3>
                                <div className={`inline-block px-2 py-0.5 rounded text-[10px] font-black uppercase tracking-wider border ${getTierColor(badge.tier)}`}>
                                    {badge.tier}
                                </div>
                            </div>
                        </div>

                        <p className="text-sm text-slate-400 mb-4 h-10 overflow-hidden text-ellipsis line-clamp-2">
                            {badge.description}
                        </p>

                        <div className="bg-navy-900/60 rounded-lg py-2 px-3 border border-navy-700/30 flex items-center justify-between">
                            <div className="flex flex-col">
                                <span className="text-[10px] uppercase text-slate-500 font-bold tracking-wider">Trigger</span>
                                <span className="text-sm text-slate-300 capitalize">{badge.trigger}</span>
                            </div>
                            {badge.threshold !== null && (
                                <div className="flex flex-col text-right">
                                    <span className="text-[10px] uppercase text-slate-500 font-bold tracking-wider">Threshold</span>
                                    <span className="text-lg font-bold text-accent-green leading-none">{badge.threshold}</span>
                                </div>
                            )}
                        </div>
                    </div>
                ))}

                {badges.length === 0 && !loading && (
                    <div className="col-span-full text-center py-20 bg-navy-800/50 border-2 border-dashed border-navy-700 rounded-2xl">
                        <Award size={48} className="mx-auto text-slate-600 mb-4" />
                        <h3 className="text-xl font-bold text-slate-400">No badges defined</h3>
                        <p className="text-slate-500 mt-2">Create your first achievement badge to start gamification.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Badges;

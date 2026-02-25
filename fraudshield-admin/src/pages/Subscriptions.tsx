import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { CreditCard, Edit2, Trash2, Plus, CheckCircle2 } from 'lucide-react';

interface SubscriptionPlan {
    id: string;
    name: string;
    price: number;
    features: string[];
    durationDays: number;
}

const Subscriptions = () => {
    const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
    const [loading, setLoading] = useState(true);
    const [isEditing, setIsEditing] = useState<SubscriptionPlan | null>(null);
    const [isCreating, setIsCreating] = useState(false);

    // Form State
    const [name, setName] = useState('');
    const [price, setPrice] = useState<string | number>('');
    const [durationDays, setDurationDays] = useState<string | number>('');
    const [features, setFeatures] = useState('');

    const fetchPlans = async () => {
        try {
            const response = await adminService.getSubscriptionPlans();
            setPlans(response.data);
        } catch (error) {
            console.error('Error fetching plans:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchPlans();
    }, []);

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        const featureList = features.split('\n').filter(f => f.trim() !== '');

        const payload = {
            name,
            price: Number(price),
            durationDays: Number(durationDays),
            features: featureList,
        };

        try {
            if (isEditing) {
                await adminService.updateSubscriptionPlan(isEditing.id, payload);
            } else {
                await adminService.createSubscriptionPlan(payload);
            }
            fetchPlans();
            resetForm();
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to save plan');
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm('Are you sure you want to delete this plan?')) return;
        try {
            await adminService.deleteSubscriptionPlan(id);
            setPlans(plans.filter(p => p.id !== id));
        } catch (error: any) {
            alert(error.response?.data?.message || 'Failed to delete plan');
        }
    };

    const resetForm = () => {
        setIsEditing(null);
        setIsCreating(false);
        setName('');
        setPrice('');
        setDurationDays('');
        setFeatures('');
    };

    const startEdit = (plan: SubscriptionPlan) => {
        setIsEditing(plan);
        setName(plan.name);
        setPrice(plan.price);
        setDurationDays(plan.durationDays);
        setFeatures(plan.features.join('\n'));
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    if (loading) return <div className="text-white">Loading...</div>;

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold">Subscription Plans</h2>
                    <p className="text-slate-400">Manage premium tiers and billing features</p>
                </div>
                {!isCreating && !isEditing && (
                    <button
                        onClick={() => setIsCreating(true)}
                        className="bg-accent-green hover:bg-green-500 text-navy-900 font-bold py-2 px-4 rounded-lg flex items-center space-x-2 transition-colors"
                    >
                        <Plus size={18} />
                        <span>Create Plan</span>
                    </button>
                )}
            </header>

            {(isCreating || isEditing) && (
                <div className="glass-card p-6 rounded-2xl mb-8 animate-slide-up">
                    <h3 className="text-xl font-bold text-white mb-4">
                        {isEditing ? 'Edit Subscription Plan' : 'Create New Plan'}
                    </h3>
                    <form onSubmit={handleSave} className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Plan Name</label>
                                <input
                                    type="text"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Price (RM)</label>
                                <input
                                    type="number"
                                    step="0.01"
                                    value={price}
                                    onChange={(e) => setPrice(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Duration (Days)</label>
                                <input
                                    type="number"
                                    value={durationDays}
                                    onChange={(e) => setDurationDays(e.target.value)}
                                    className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                    required
                                />
                            </div>
                        </div>
                        <div>
                            <label className="block text-slate-400 text-xs font-bold uppercase mb-2">Features (One per line)</label>
                            <textarea
                                value={features}
                                onChange={(e) => setFeatures(e.target.value)}
                                rows={4}
                                className="w-full bg-navy-900/50 border border-navy-700 rounded-xl p-3 text-white focus:border-accent-green outline-none"
                                required
                            />
                        </div>
                        <div className="flex space-x-3 pt-2">
                            <button
                                type="submit"
                                className="bg-accent-green text-navy-900 font-bold py-2 px-6 rounded-lg hover:bg-green-500 transition-colors"
                            >
                                Save Plan
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

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {plans.map((plan, idx) => (
                    <div
                        key={plan.id}
                        className="glass-card p-6 rounded-2xl animate-slide-up flex flex-col"
                        style={{ animationDelay: `${idx * 100}ms` }}
                    >
                        <div className="flex justify-between items-start mb-4">
                            <div className="bg-accent-green/10 p-3 rounded-lg text-accent-green">
                                <CreditCard size={24} />
                            </div>
                            <div className="flex space-x-2">
                                <button
                                    onClick={() => startEdit(plan)}
                                    className="text-slate-400 hover:text-white p-1 transition-colors"
                                >
                                    <Edit2 size={18} />
                                </button>
                                <button
                                    onClick={() => handleDelete(plan.id)}
                                    className="text-slate-400 hover:text-accent-red p-1 transition-colors"
                                >
                                    <Trash2 size={18} />
                                </button>
                            </div>
                        </div>

                        <h3 className="text-2xl font-bold text-white mb-1">{plan.name}</h3>
                        <div className="flex items-baseline space-x-1 mb-4">
                            <span className="text-3xl font-black text-white">RM {plan.price.toFixed(2)}</span>
                            <span className="text-slate-400 text-sm">/ {plan.durationDays} days</span>
                        </div>

                        <div className="bg-navy-900/40 rounded-xl p-4 flex-1 border border-navy-700/50">
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Included Features</h4>
                            <ul className="space-y-2">
                                {plan.features.map((feature, i) => (
                                    <li key={i} className="flex items-start text-sm text-slate-300">
                                        <CheckCircle2 size={16} className="text-accent-green mr-2 shrink-0 mt-0.5" />
                                        <span>{feature}</span>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                ))}

                {plans.length === 0 && !loading && (
                    <div className="col-span-full text-center py-20 bg-navy-800/50 border-2 border-dashed border-navy-700 rounded-2xl">
                        <CreditCard size={48} className="mx-auto text-slate-600 mb-4" />
                        <h3 className="text-xl font-bold text-slate-400">No subscription plans configured</h3>
                        <p className="text-slate-500 mt-2">Create a plan to get started with monetization.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Subscriptions;

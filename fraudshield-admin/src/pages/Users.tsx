import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { User as UserIcon, Mail, X, Loader2, Save, ShieldCheck, ShieldX } from 'lucide-react';

interface SubscriptionPlan {
    id: string;
    name: string;
    price: number;
    durationDays: number;
}

interface UserSubscription {
    id: string;
    isActive: boolean;
    endDate: string;
    plan: SubscriptionPlan;
}

interface UserProfile {
    preferredName?: string;
    mobile?: string;
    mailingAddress?: string;
    points?: number;
    bio?: string;
}

interface User {
    id: string;
    email: string;
    fullName: string | null;
    role: string;
    createdAt: string;
    emailVerified: boolean;
    subscriptions?: UserSubscription[];
    profile?: UserProfile | null;
}

const getActiveSub = (user: User) =>
    user.subscriptions?.find(s => s.isActive && new Date(s.endDate) > new Date()) || null;

const Users = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [drawerLoading, setDrawerLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
    const [saveSuccess, setSaveSuccess] = useState(false);

    // Form state for editing
    const [form, setForm] = useState({
        fullName: '',
        email: '',
        preferredName: '',
        mobile: '',
        mailingAddress: '',
        role: 'user',
        planId: '',
    });

    const fetchUsers = async () => {
        try {
            const response = await adminService.getUsers();
            setUsers(response.data);
        } catch (error) {
            console.error('Error fetching users:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchPlans = async () => {
        try {
            const response = await adminService.getSubscriptionPlans();
            setPlans(response.data);
        } catch (error) {
            console.error('Error fetching plans:', error);
        }
    };

    useEffect(() => {
        fetchUsers();
        fetchPlans();
    }, []);

    const handleRowClick = async (user: User) => {
        setDrawerOpen(true);
        setDrawerLoading(true);
        setSaveSuccess(false);
        try {
            const res = await adminService.getUserById(user.id);
            const fullUser: User = res.data;
            setSelectedUser(fullUser);
            const activeSub = getActiveSub(fullUser);
            setForm({
                fullName: fullUser.fullName || '',
                email: fullUser.email,
                preferredName: fullUser.profile?.preferredName || '',
                mobile: fullUser.profile?.mobile || '',
                mailingAddress: fullUser.profile?.mailingAddress || '',
                role: fullUser.role,
                planId: activeSub?.plan.id || '',
            });
        } catch (e) {
            console.error('Error loading user details:', e);
        } finally {
            setDrawerLoading(false);
        }
    };

    const handleSave = async () => {
        if (!selectedUser) return;
        setSaving(true);
        try {
            const payload: any = {
                fullName: form.fullName,
                email: form.email,
                role: form.role,
                preferredName: form.preferredName,
                mobile: form.mobile,
                mailingAddress: form.mailingAddress,
                planId: form.planId, // Always send, even empty string means "set to free"
            };

            const res = await adminService.updateUser(selectedUser.id, payload);
            const updatedUser: User = res.data;

            // Refresh the entire list so the Tier column reflects the change
            await fetchUsers();
            setSaveSuccess(true);
            setSelectedUser(updatedUser);
            setTimeout(() => setSaveSuccess(false), 3000);
        } catch (error) {
            alert('Failed to update user');
        } finally {
            setSaving(false);
        }
    };

    if (loading) return <div className="text-white">Loading...</div>;

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold">User Management</h2>
                    <p className="text-slate-400">Click a row to view and edit user details</p>
                </div>
                <div className="text-sm text-slate-400 bg-navy-800 px-4 py-2 rounded-lg border border-navy-700">
                    Total Users: <span className="text-white font-bold">{users.length}</span>
                </div>
            </header>

            <div className="glass-card rounded-2xl overflow-hidden animate-slide-up">
                <table className="w-full text-left">
                    <thead className="bg-navy-700 text-slate-400 text-sm uppercase tracking-wider">
                        <tr>
                            <th className="px-6 py-4 font-semibold">User</th>
                            <th className="px-6 py-4 font-semibold">Role</th>
                            <th className="px-6 py-4 font-semibold">Tier</th>
                            <th className="px-6 py-4 font-semibold text-center">Verified</th>
                            <th className="px-6 py-4 font-semibold">Joined</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-navy-700">
                        {users.map((user) => {
                            const activeSub = getActiveSub(user);
                            return (
                                <tr
                                    key={user.id}
                                    className="hover:bg-navy-700/50 transition-colors cursor-pointer"
                                    onClick={() => handleRowClick(user)}
                                >
                                    <td className="px-6 py-4">
                                        <div className="flex items-center space-x-3">
                                            <div className="bg-navy-700 p-2 rounded-full">
                                                <UserIcon size={20} className="text-slate-400" />
                                            </div>
                                            <div>
                                                <div className="font-medium text-white">{user.fullName || 'No Name'}</div>
                                                <div className="text-xs text-slate-400 flex items-center mt-1">
                                                    <Mail size={12} className="mr-1" /> {user.email}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-widest ${user.role === 'admin'
                                            ? 'bg-accent-green/20 text-accent-green border border-accent-green/30'
                                            : 'bg-slate-700 text-slate-300 border border-slate-600'
                                            }`}>
                                            {user.role}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-bold tracking-widest ${activeSub
                                            ? 'bg-yellow-400/20 text-yellow-500 border border-yellow-400/30'
                                            : 'bg-slate-700 text-slate-300 border border-slate-600'
                                            }`}>
                                            {activeSub ? activeSub.plan.name.toUpperCase() : 'FREE'}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex justify-center">
                                            {user.emailVerified ? (
                                                <div className="flex items-center text-accent-green bg-accent-green/10 px-2 py-1 rounded-lg border border-accent-green/20 text-[10px] font-bold uppercase tracking-wider">
                                                    <ShieldCheck size={12} className="mr-1" /> Verified
                                                </div>
                                            ) : (
                                                <div className="flex items-center text-red-400 bg-red-400/10 px-2 py-1 rounded-lg border border-red-400/20 text-[10px] font-bold uppercase tracking-wider">
                                                    <ShieldX size={12} className="mr-1" /> Unverified
                                                </div>
                                            )}
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-slate-400">
                                        {new Date(user.createdAt).toLocaleDateString()}
                                    </td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>

            {/* Drawer Overlay */}
            {drawerOpen && (
                <div className="fixed inset-0 z-50 flex">
                    {/* Backdrop */}
                    <div
                        className="flex-1 bg-black/60 backdrop-blur-sm"
                        onClick={() => setDrawerOpen(false)}
                    />

                    {/* Drawer Panel */}
                    <div className="w-full max-w-lg bg-navy-900 border-l border-navy-700 flex flex-col h-full shadow-2xl">
                        {/* Header */}
                        <div className="flex items-center justify-between p-6 border-b border-navy-700">
                            <div>
                                <h3 className="text-xl font-bold text-white">User Details</h3>
                                <p className="text-sm text-slate-400">Edit user profile and subscription</p>
                            </div>
                            <button
                                onClick={() => setDrawerOpen(false)}
                                className="p-2 rounded-lg hover:bg-navy-700 text-slate-400 hover:text-white transition-colors"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Content */}
                        <div className="flex-1 overflow-y-auto p-6 space-y-6">
                            {drawerLoading ? (
                                <div className="flex items-center justify-center py-20">
                                    <Loader2 size={32} className="animate-spin text-accent-green" />
                                </div>
                            ) : (
                                <>
                                    {/* Account Info */}
                                    <section>
                                        <h4 className="text-xs font-bold uppercase tracking-widest text-slate-500 mb-3">Account Information</h4>
                                        <div className="space-y-3">
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Customer Name</label>
                                                <input
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.fullName}
                                                    onChange={e => setForm({ ...form, fullName: e.target.value })}
                                                    placeholder="Full Name"
                                                />
                                            </div>
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Preferred Name</label>
                                                <input
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.preferredName}
                                                    onChange={e => setForm({ ...form, preferredName: e.target.value })}
                                                    placeholder="Preferred / Nickname"
                                                />
                                            </div>
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Email Address</label>
                                                <input
                                                    type="email"
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.email}
                                                    onChange={e => setForm({ ...form, email: e.target.value })}
                                                    placeholder="user@example.com"
                                                />
                                            </div>
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Mobile Number</label>
                                                <input
                                                    type="tel"
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.mobile}
                                                    onChange={e => setForm({ ...form, mobile: e.target.value })}
                                                    placeholder="+60 12-3456789"
                                                />
                                            </div>
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Mailing Address</label>
                                                <textarea
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green resize-none"
                                                    rows={3}
                                                    value={form.mailingAddress}
                                                    onChange={e => setForm({ ...form, mailingAddress: e.target.value })}
                                                    placeholder="No. 1, Jalan Example, 50000 Kuala Lumpur"
                                                />
                                            </div>
                                        </div>
                                    </section>

                                    {/* Role & Tier */}
                                    <section>
                                        <h4 className="text-xs font-bold uppercase tracking-widest text-slate-500 mb-3">Access & Subscription</h4>
                                        <div className="space-y-3">
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">System Role</label>
                                                <select
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.role}
                                                    onChange={e => setForm({ ...form, role: e.target.value })}
                                                >
                                                    <option value="user">User</option>
                                                    <option value="admin">Admin</option>
                                                </select>
                                            </div>
                                            <div>
                                                <label className="text-xs text-slate-400 mb-1 block">Subscription Plan</label>
                                                <select
                                                    className="w-full bg-navy-800 border border-navy-600 rounded-lg px-4 py-2.5 text-white text-sm focus:outline-none focus:border-accent-green"
                                                    value={form.planId}
                                                    onChange={e => setForm({ ...form, planId: e.target.value })}
                                                >
                                                    <option value="">Free (No Plan)</option>
                                                    {plans.map(plan => (
                                                        <option key={plan.id} value={plan.id}>
                                                            {plan.name} — RM{plan.price}/mo
                                                        </option>
                                                    ))}
                                                </select>
                                                {form.planId && (
                                                    <p className="text-xs text-slate-500 mt-1">
                                                        Saving will assign a new subscription starting today.
                                                    </p>
                                                )}
                                            </div>
                                        </div>
                                    </section>

                                    {/* User metadata */}
                                    {selectedUser && (
                                        <section className="bg-navy-800 rounded-xl p-4 border border-navy-700 text-sm space-y-2">
                                            <h4 className="text-xs font-bold uppercase tracking-widest text-slate-500 mb-2">Read-only Info</h4>
                                            <div className="flex justify-between text-slate-400">
                                                <span>User ID</span>
                                                <span className="font-mono text-xs text-slate-300 truncate max-w-[60%]">{selectedUser.id}</span>
                                            </div>
                                            <div className="flex justify-between text-slate-400">
                                                <span>Email Verified</span>
                                                <span className={selectedUser.emailVerified ? 'text-accent-green' : 'text-red-400'}>
                                                    {selectedUser.emailVerified ? 'Yes' : 'No'}
                                                </span>
                                            </div>
                                            <div className="flex justify-between text-slate-400">
                                                <span>Joined</span>
                                                <span className="text-slate-300">{new Date(selectedUser.createdAt).toLocaleDateString()}</span>
                                            </div>
                                            {selectedUser.profile?.points !== undefined && (
                                                <div className="flex justify-between text-slate-400">
                                                    <span>Points Balance</span>
                                                    <span className="text-accent-green font-bold">{selectedUser.profile.points} pts</span>
                                                </div>
                                            )}
                                        </section>
                                    )}
                                </>
                            )}
                        </div>

                        {/* Footer with Save */}
                        <div className="p-6 border-t border-navy-700 flex items-center space-x-3">
                            {saveSuccess && (
                                <span className="text-accent-green text-sm font-medium flex-1">✓ Saved successfully!</span>
                            )}
                            {!saveSuccess && <div className="flex-1" />}
                            <button
                                onClick={() => setDrawerOpen(false)}
                                className="px-4 py-2 rounded-lg bg-navy-700 text-slate-300 hover:bg-navy-600 transition-colors text-sm"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleSave}
                                disabled={saving || drawerLoading}
                                className="px-6 py-2 rounded-lg bg-accent-green text-navy-900 font-bold hover:bg-green-400 transition-colors text-sm flex items-center space-x-2 disabled:opacity-60"
                            >
                                {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                                <span>{saving ? 'Saving...' : 'Save Changes'}</span>
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Users;

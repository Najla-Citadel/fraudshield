import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Shield, ShieldAlert, User as UserIcon, Mail } from 'lucide-react';

interface User {
    id: string;
    email: string;
    fullName: string | null;
    role: string;
    createdAt: string;
    emailVerified: boolean;
}

const Users = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);

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

    useEffect(() => {
        fetchUsers();
    }, []);

    const handleRoleToggle = async (user: User) => {
        const newRole = user.role === 'admin' ? 'user' : 'admin';
        try {
            await adminService.updateUserRole(user.id, newRole);
            setUsers(users.map(u => u.id === user.id ? { ...u, role: newRole } : u));
        } catch (error) {
            alert('Failed to update role');
        }
    };

    if (loading) return <div className="text-white">Loading...</div>;

    return (
        <div>
            <header className="mb-8 flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold">User Management</h2>
                    <p className="text-slate-400">View and manage system users and roles</p>
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
                            <th className="px-6 py-4 font-semibold">Joined</th>
                            <th className="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-navy-700">
                        {users.map((user) => (
                            <tr key={user.id} className="hover:bg-navy-700/50 transition-colors">
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
                                <td className="px-6 py-4 text-sm text-slate-400">
                                    {new Date(user.createdAt).toLocaleDateString()}
                                </td>
                                <td className="px-6 py-4 text-right">
                                    <button
                                        onClick={() => handleRoleToggle(user)}
                                        className={`inline-flex items-center space-x-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${user.role === 'admin'
                                            ? 'text-accent-red hover:bg-accent-red/10'
                                            : 'text-accent-green hover:bg-accent-green/10'
                                            }`}
                                    >
                                        {user.role === 'admin' ? (
                                            <><ShieldAlert size={14} /> <span>Demote</span></>
                                        ) : (
                                            <><Shield size={14} /> <span>Promote</span></>
                                        )}
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Users;

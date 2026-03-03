import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { Lock, Mail, ShieldCheck, AlertCircle } from 'lucide-react';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const response = await api.post('/auth/login', { email, password });
<<<<<<< HEAD
            const { token, user } = response.data;
=======
            const { token, refreshToken, user } = response.data;
>>>>>>> dev-ui2

            if (user.role !== 'admin') {
                setError('Access denied. You do not have administrative privileges.');
                setLoading(false);
                return;
            }

            localStorage.setItem('adminToken', token);
<<<<<<< HEAD
=======
            localStorage.setItem('adminRefreshToken', refreshToken);
>>>>>>> dev-ui2
            localStorage.setItem('adminUser', JSON.stringify(user));
            navigate('/');
        } catch (err: any) {
            setError(err.response?.data?.message || 'Login failed. Please check your credentials.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-navy-900 flex items-center justify-center p-4">
            <div className="max-w-md w-full">
                <div className="text-center mb-10">
                    <div className="bg-accent-green/10 w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-6 border border-accent-green/20">
                        <ShieldCheck size={40} className="text-accent-green" />
                    </div>
                    <h1 className="text-4xl font-bold text-white mb-2">FraudShield</h1>
                    <p className="text-slate-400 uppercase tracking-widest text-sm font-semibold">Admin Command Center</p>
                </div>

                <div className="glass-card p-10 rounded-2xl relative overflow-hidden animate-slide-up">
                    <div className="absolute top-0 left-0 w-full h-1 bg-accent-green"></div>

                    <form onSubmit={handleLogin} className="space-y-6">
                        {error && (
                            <div className="bg-accent-red/10 border border-accent-red/20 text-accent-red p-4 rounded-xl flex items-center space-x-3 text-sm animate-shake">
                                <AlertCircle size={18} />
                                <span>{error}</span>
                            </div>
                        )}

                        <div>
                            <label className="block text-slate-400 text-xs font-bold uppercase mb-2 ml-1">Email Address</label>
                            <div className="relative">
                                <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="w-full bg-navy-900 border border-navy-700 rounded-xl py-3.5 pl-12 pr-4 text-white focus:border-accent-green focus:ring-1 focus:ring-accent-green transition-all outline-none"
                                    placeholder="admin@fraudshield.com"
                                    required
                                />
                            </div>
                        </div>

                        <div>
                            <label className="block text-slate-400 text-xs font-bold uppercase mb-2 ml-1">Password</label>
                            <div className="relative">
                                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="w-full bg-navy-900 border border-navy-700 rounded-xl py-3.5 pl-12 pr-4 text-white focus:border-accent-green focus:ring-1 focus:ring-accent-green transition-all outline-none"
                                    placeholder="••••••••"
                                    required
                                />
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full bg-accent-green hover:bg-green-500 disabled:bg-slate-700 text-navy-900 font-bold py-4 rounded-xl transition-all shadow-lg shadow-accent-green/10 flex items-center justify-center space-x-2 text-lg mt-8"
                        >
                            {loading ? (
                                <div className="w-6 h-6 border-4 border-navy-900/30 border-t-navy-900 rounded-full animate-spin"></div>
                            ) : (
                                <>
                                    <span>Initialize Secure Access</span>
                                </>
                            )}
                        </button>
                    </form>
                </div>

                <p className="text-center text-slate-500 mt-8 text-sm">
                    &copy; 2026 FraudShield Global Operations. Authorized Personnel Only.
                </p>
            </div>
        </div>
    );
};

export default Login;

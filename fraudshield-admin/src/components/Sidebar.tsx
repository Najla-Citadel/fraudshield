import { LayoutDashboard, Users, AlertTriangle, LogOut, CreditCard, Award, ShoppingBag, Radio, Search } from 'lucide-react';
import { NavLink, useNavigate } from 'react-router-dom';

const Sidebar = () => {
    const navigate = useNavigate();

    const handleLogout = () => {
        localStorage.removeItem('adminToken');
<<<<<<< HEAD
=======
        localStorage.removeItem('adminRefreshToken');
        localStorage.removeItem('adminUser');
>>>>>>> dev-ui2
        navigate('/login');
    };

    const navItems = [
        { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
        { icon: Users, label: 'Users', path: '/users' },
        { icon: AlertTriangle, label: 'Scam Reports', path: '/reports' },
        { icon: CreditCard, label: 'Subscriptions', path: '/subscriptions' },
        { icon: Award, label: 'Badges', path: '/badges' },
        { icon: ShoppingBag, label: 'Store & Rewards', path: '/rewards' },
        { icon: Radio, label: 'Broadcaster', path: '/broadcasts' },
        { icon: Search, label: 'Fraud Analysis', path: '/fraud-analysis' },
    ];

    return (
        <div className="w-64 glass-panel h-screen flex flex-col z-10 transition-all duration-300">
            <div className="p-6">
                <h1 className="text-3xl font-bold gradient-text pb-1">FraudShield</h1>
                <p className="text-[10px] font-semibold text-slate-400 mt-1 uppercase tracking-[0.2em]">Admin Command Center</p>
            </div>

            <nav className="flex-1 px-4 py-4 space-y-2">
                {navItems.map((item) => (
                    <NavLink
                        key={item.path}
                        to={item.path}
                        className={({ isActive }) =>
                            `flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${isActive
                                ? 'bg-accent-green/10 text-accent-green'
                                : 'text-slate-400 hover:bg-navy-700 hover:text-white'
                            }`
                        }
                    >
                        <item.icon size={20} />
                        <span className="font-medium">{item.label}</span>
                    </NavLink>
                ))}
            </nav>

            <div className="p-4 border-t border-navy-700">
                <button
                    onClick={handleLogout}
                    className="flex items-center space-x-3 px-4 py-3 w-full text-slate-400 hover:text-accent-red hover:bg-accent-red/10 rounded-lg transition-colors"
                >
                    <LogOut size={20} />
                    <span className="font-medium">Logout</span>
                </button>
            </div>
        </div>
    );
};

export default Sidebar;

import { useEffect, useState } from 'react';
import { adminService } from '../services/api';
import { Shield, Search, Globe, Phone, CreditCard, AlertTriangle, TrendingUp } from 'lucide-react';

interface ScamEntity {
    phoneNumber?: string;
    url?: string;
    accountNumber?: string;
    bankName?: string;
    riskScore: number;
    reportCount: number;
    verifiedCount: number;
    categories: string[];
    lastReported: string;
}

const GlobalDatabase = () => {
    const [type, setType] = useState('phone');
    const [entities, setEntities] = useState<ScamEntity[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [total, setTotal] = useState(0);

    const fetchEntities = async () => {
        setLoading(true);
        try {
            const response = await adminService.getGlobalEntities({
                type,
                search,
                limit: 15
            });
            setEntities(response.data.results);
            setTotal(response.data.total);
        } catch (error) {
            console.error('Error fetching global entities:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        const timer = setTimeout(() => {
            fetchEntities();
        }, 300);
        return () => clearTimeout(timer);
    }, [type, search]);

    const getRiskColor = (score: number) => {
        if (score >= 75) return 'text-accent-red bg-accent-red/10 border-accent-red/20';
        if (score >= 40) return 'text-yellow-400 bg-yellow-400/10 border-yellow-400/20';
        return 'text-accent-green bg-accent-green/10 border-accent-green/20';
    };

    const getEntityIcon = () => {
        switch (type) {
            case 'phone': return <Phone size={20} className="text-accent-green" />;
            case 'url': return <Globe size={20} className="text-accent-green" />;
            case 'bank': return <CreditCard size={20} className="text-accent-green" />;
            default: return <Shield size={20} className="text-accent-green" />;
        }
    };

    const getEntityValue = (entity: ScamEntity) => {
        return entity.phoneNumber || entity.url || entity.accountNumber;
    };

    return (
        <div className="animate-fade-in text-white">
            <header className="mb-8">
                <div className="flex justify-between items-end">
                    <div>
                        <h2 className="text-3xl font-bold">Global Scam Database</h2>
                        <p className="text-slate-400 mt-1">Crowdsourced intelligence ({total} verified entities)</p>
                    </div>
                    <div className="bg-navy-800 p-1.5 rounded-xl border border-navy-700 flex space-x-1">
                        {[
                            { id: 'phone', label: 'Phone Numbers', icon: Phone },
                            { id: 'url', label: 'Malicious URLs', icon: Globe },
                            { id: 'bank', label: 'Mule Accounts', icon: CreditCard },
                        ].map((tab) => (
                            <button
                                key={tab.id}
                                onClick={() => setType(tab.id)}
                                className={`flex items-center space-x-2 px-4 py-2 rounded-lg text-sm font-bold transition-all ${
                                    type === tab.id 
                                    ? 'bg-accent-green text-navy-900 shadow-lg shadow-accent-green/20' 
                                    : 'text-slate-400 hover:bg-navy-700 hover:text-white'
                                }`}
                            >
                                <tab.icon size={16} />
                                <span>{tab.label}</span>
                            </button>
                        ))}
                    </div>
                </div>

                <div className="mt-6 flex items-center bg-navy-800 border border-navy-700 rounded-2xl px-4 py-3 focus-within:ring-2 focus-within:ring-accent-green/50 transition-all max-w-2xl">
                    <Search className="text-slate-400 mr-3" size={20} />
                    <input
                        type="text"
                        placeholder={`Search ${type === 'phone' ? 'numbers' : type === 'url' ? 'URLs' : 'accounts'}...`}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        className="bg-transparent border-none text-white placeholder-slate-500 focus:outline-none w-full font-medium"
                    />
                </div>
            </header>

            {loading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                    {[1, 2, 3, 4, 5, 6].map((i) => (
                        <div key={i} className="glass-card h-48 rounded-2xl animate-pulse bg-navy-800/50 border border-navy-700"></div>
                    ))}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                    {entities.map((entity, idx) => (
                        <div 
                            key={idx} 
                            className="glass-card rounded-2xl p-6 border border-navy-700/50 hover:border-accent-green/30 transition-all group animate-slide-up"
                            style={{ animationDelay: `${idx * 50}ms` }}
                        >
                            <div className="flex justify-between items-start mb-4">
                                <div className="p-2.5 bg-navy-700 rounded-xl border border-navy-600 group-hover:bg-accent-green/10 group-hover:border-accent-green/20 transition-colors">
                                    {getEntityIcon()}
                                </div>
                                <div className={`px-3 py-1 rounded-full text-xs font-black border uppercase flex items-center space-x-1.5 ${getRiskColor(entity.riskScore)}`}>
                                    <TrendingUp size={12} />
                                    <span>{entity.riskScore}% RISK</span>
                                </div>
                            </div>

                            <div className="mb-4">
                                <h3 className="text-lg font-bold truncate mb-1" title={getEntityValue(entity)}>
                                    {getEntityValue(entity)}
                                </h3>
                                {entity.bankName && (
                                    <p className="text-xs text-accent-green uppercase font-bold tracking-wider">{entity.bankName}</p>
                                )}
                            </div>

                            <div className="flex flex-wrap gap-1.5 mb-6">
                                {entity.categories.map((cat, i) => (
                                    <span key={i} className="px-2 py-0.5 bg-navy-900 border border-navy-700 rounded text-[10px] font-bold text-slate-400 uppercase tracking-tighter">
                                        {cat}
                                    </span>
                                ))}
                                {entity.categories.length === 0 && (
                                    <span className="text-[10px] font-bold text-slate-600 italic uppercase">Uncategorized Target</span>
                                )}
                            </div>

                            <div className="pt-4 border-t border-navy-700 flex justify-between items-center text-xs">
                                <div className="flex space-x-4">
                                    <div className="flex flex-col">
                                        <span className="text-slate-500 font-bold uppercase text-[9px]">Reports</span>
                                        <span className="text-white font-mono">{entity.reportCount}</span>
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="text-slate-500 font-bold uppercase text-[9px]">Verified</span>
                                        <span className="text-accent-green font-mono">{entity.verifiedCount}</span>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <span className="text-slate-500 font-bold uppercase text-[9px] block">Updated</span>
                                    <span className="text-slate-300 font-medium">{new Date(entity.lastReported).toLocaleDateString()}</span>
                                </div>
                            </div>
                        </div>
                    ))}

                    {entities.length === 0 && (
                        <div className="col-span-full py-20 bg-navy-800/30 border-2 border-dashed border-navy-700 rounded-3xl text-center">
                            <AlertTriangle size={48} className="mx-auto text-slate-600 mb-4" />
                            <h3 className="text-xl font-bold text-slate-400">No verified entities found</h3>
                            <p className="text-slate-500 mt-1 max-w-sm mx-auto font-medium">Try adjusting your search query or check back later as more reports get approved.</p>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

export default GlobalDatabase;

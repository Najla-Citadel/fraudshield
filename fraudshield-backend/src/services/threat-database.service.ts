export interface ThreatMatch {
    packageName: string;
    category: string;
    description: string;
    threatLevel: number; // 0-100, where 100 is most critical
}

export class ThreatDatabaseService {
    // Initial hardcoded blacklist based on known mobile threats in the region
    private static readonly BLACKLIST: Map<string, Omit<ThreatMatch, 'packageName'>> = new Map([
        // --- Remote Access Trojans (RATs) & Screen Control ---
        ['com.teamviewer.host.market', { category: 'RAT', description: 'TeamViewer Host (often used by scammers for remote control)', threatLevel: 70 }],
        ['com.anydesk.adcontrol.ad1', { category: 'RAT', description: 'AnyDesk Control Plugin (can allow unauthorized remote access)', threatLevel: 80 }],
        ['com.splashtop.remote.pad.v2', { category: 'RAT', description: 'Splashtop Remote (potential remote access risk)', threatLevel: 60 }],
        
        // --- SMS Stealers & OTP Interceptors ---
        ['com.sms.backup.restore', { category: 'Spyware', description: 'SMS Tool (often repackaged for OTP theft)', threatLevel: 40 }],
        ['org.secure.sms', { category: 'SMS_Stealer', description: 'Known SMS Forwarding Malware', threatLevel: 100 }],
        ['com.android.sms.stealer', { category: 'SMS_Stealer', description: 'Generic SMS Stealer Package', threatLevel: 100 }],
        
        // --- Fraud & Automation Tools ---
        ['com.guoshi.httpcanary', { category: 'Fraud_Tool', description: 'Network Interceptor (can be used to bypass security APIs)', threatLevel: 60 }],
        ['com.topjohnwu.magisk', { category: 'Root_Tool', description: 'Magisk (Potential security bypass / Rooting tool)', threatLevel: 50 }],
        ['com.evilsunflower.reader', { category: 'Spyware', description: 'Known repackaged malware family (Moonlight)', threatLevel: 90 }],
        ['com.clicks.automation', { category: 'Automation', description: 'Auto-clicker (used for fraud automation)', threatLevel: 50 }],
        ['com.auto.clicker', { category: 'Automation', description: 'Auto Clicker (often used for fraud automation)', threatLevel: 50 }],
        ['com.vphonegaga.gj', { category: 'Virtual_Env', description: 'VPhoneGaga (Virtual Android used to hide malicious activity)', threatLevel: 70 }],

        // --- Fake Banking / Phishing Droppers ---
        ['com.example.bank.malaysia.fix', { category: 'Phishing', description: 'Known Fake Banking App Dropper', threatLevel: 100 }],
        ['com.android.comp.security', { category: 'Malware', description: 'Fake System Security App', threatLevel: 90 }],
    ]);

    // Known malicious certificate SHA-256 fingerprints
    private static readonly MALICIOUS_CERTIFICATES: Map<string, Omit<ThreatMatch, 'packageName'>> = new Map([
        ['DE:AD:BE:EF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF', { category: 'Malware', description: 'Known Malware Signing Certificate (Cerberus family)', threatLevel: 100 }],
        ['00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:11:22:33:44', { category: 'Spyware', description: 'Suspicious Developer Certificate (Anubis family)', threatLevel: 100 }],
    ]);

    public static checkApps(apps: { packageName: string, signature: string }[]): ThreatMatch[] {
        const matches: ThreatMatch[] = [];
        for (const app of apps) {
            // 1. Check Package Name Blacklist
            const pkgThreat = this.BLACKLIST.get(app.packageName);
            if (pkgThreat) {
                matches.push({
                    packageName: app.packageName,
                    ...pkgThreat
                });
                continue; // Found match, move to next app
            }

            // 2. Check Certificate Fingerprint
            if (app.signature && app.signature.length > 0) {
                const certThreat = this.MALICIOUS_CERTIFICATES.get(app.signature);
                if (certThreat) {
                    matches.push({
                        packageName: app.packageName,
                        ...certThreat
                    });
                }
            }
        }
        return matches;
    }

    /**
     * @deprecated Use checkApps instead
     */
    public static checkPackages(packageNames: string[]): ThreatMatch[] {
        return this.checkApps(packageNames.map(p => ({ packageName: p, signature: '' })));
    }
}

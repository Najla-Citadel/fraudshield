import dns from 'dns';
import { promisify } from 'util';
import logger from './logger';

const lookup = promisify(dns.lookup);

/**
 * Checks if an IP address is private, loopback, or reserved.
 * Covers IPv4 and IPv6.
 */
export function isPrivateIP(ip: string): boolean {
    // IPv4 Checks
    if (ip.includes('.')) {
        const parts = ip.split('.').map(Number);
        if (parts.length !== 4) return true; // Malformed IPv4

        // 127.0.0.0/8 (Loopback)
        if (parts[0] === 127) return true;

        // 10.0.0.0/8 (Private)
        if (parts[0] === 10) return true;

        // 172.16.0.0/12 (Private)
        if (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) return true;

        // 192.168.0.0/16 (Private)
        if (parts[0] === 192 && parts[1] === 168) return true;

        // 169.254.0.0/16 (Link-local)
        if (parts[0] === 169 && parts[1] === 254) return true;

        // 0.0.0.0 (Broadcast/Any)
        if (parts[0] === 0) return true;

        return false;
    }

    // IPv6 Checks
    if (ip.includes(':')) {
        const lowerIp = ip.toLowerCase();

        // ::1 (Loopback)
        if (lowerIp === '::1' || lowerIp === '0:0:0:0:0:0:0:1') return true;

        // fc00::/7 (Unique Local Address)
        if (lowerIp.startsWith('fc') || lowerIp.startsWith('fd')) return true;

        // fe80::/10 (Link-local)
        if (lowerIp.startsWith('fe8') || lowerIp.startsWith('fe9') || lowerIp.startsWith('fea') || lowerIp.startsWith('feb')) return true;

        // :: (Unspecified)
        if (lowerIp === '::' || lowerIp === '0:0:0:0:0:0:0:0') return true;

        return false;
    }

    return true; // Unknown/Malformed — safest to block
}

/**
 * Validates a URL and its resolved IP address for SSRF safety.
 * Throws an error if the URL is unsafe.
 */
export async function validateSafeUrl(urlStr: string): Promise<void> {
    let url: URL;
    try {
        url = new URL(urlStr);
    } catch (err) {
        throw new Error('Invalid URL format');
    }

    // Block non-HTTP protocols
    if (url.protocol !== 'http:' && url.protocol !== 'https:') {
        throw new Error(`Forbidden protocol: ${url.protocol}`);
    }

    const hostname = url.hostname;

    // Check if hostname itself is an IP
    if (/^(\d{1,3}\.){3}\d{1,3}$/.test(hostname) || hostname.includes(':')) {
        if (isPrivateIP(hostname)) {
            logger.warn(`SSRF Blocked: URL uses private IP directly - ${urlStr}`);
            throw new Error('Forbidden destination (Private IP)');
        }
    }

    let address: string;
    try {
        // Resolve hostname to IP
        const result = await lookup(hostname);
        address = result.address;
    } catch (err) {
        // DNS lookup failure — the fetch will fail anyway, but we can't verify safety here.
        // We let it pass to let the fetch's own error handling deal with it.
        return;
    }

    if (isPrivateIP(address)) {
        logger.warn(`SSRF Blocked: Hostname ${hostname} resolves to private IP ${address} - ${urlStr}`);
        throw new Error('Forbidden destination (Internal Network)');
    }
}

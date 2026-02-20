import 'dart:developer';
import '../services/api_service.dart';

class RiskResult {
  final int score;
  final String level; // high, medium, low
  final List<String> reasons;
  final bool apiChecked; // Whether Safe Browsing API was consulted

  RiskResult({
    required this.score,
    required this.level,
    required this.reasons,
    this.apiChecked = false,
  });
}

class RiskEvaluator {
  static final ApiService _api = ApiService.instance;

  // ── Main entry point for URL checks (async, calls backend) ──
  static Future<RiskResult> evaluateUrl(String url) async {
    int score = 0;
    List<String> reasons = [];
    bool apiChecked = false;

    // 1. Run heuristic checks first (instant, offline)
    final heuristic = _heuristicUrlCheck(url);
    score += heuristic.score;
    reasons.addAll(heuristic.reasons);

    // 2. Call Google Safe Browsing API via backend
    try {
      final res = await _api.checkUrl(url);
      apiChecked = true;

      if (res['safe'] == false) {
        final threats = List<String>.from(res['threats'] ?? []);
        score += 90; // API-flagged = very high risk

        for (final threat in threats) {
          switch (threat) {
            case 'SOCIAL_ENGINEERING':
              reasons.insert(0, '⚠️ Phishing site detected by Google Safe Browsing');
              break;
            case 'MALWARE':
              reasons.insert(0, '⚠️ Malware distribution detected by Google Safe Browsing');
              break;
            case 'UNWANTED_SOFTWARE':
              reasons.insert(0, '⚠️ Unwanted software detected by Google Safe Browsing');
              break;
            default:
              reasons.insert(0, '⚠️ Flagged as $threat by Google Safe Browsing');
          }
        }
      } else {
        reasons.add('✅ Verified safe by Google Safe Browsing');
      }
    } catch (e) {
      log('Safe Browsing API call failed: $e');
      reasons.add('⚡ Could not verify with Google (offline check only)');
    }

    // 3. Determine level
    String level;
    if (score >= 70) {
      level = 'high';
    } else if (score >= 40) {
      level = 'medium';
    } else {
      level = 'low';
    }

    return RiskResult(
      score: score.clamp(0, 100),
      level: level,
      reasons: reasons,
      apiChecked: apiChecked,
    );
  }

  // ── Synchronous evaluate for non-URL types (phone, bank, doc) ──
  static RiskResult evaluate({
    required String type,
    required String value,
  }) {
    int score = 0;
    List<String> reasons = [];

    // 📞 PHONE NUMBER
    if (type == 'Phone No') {
      if (value.startsWith('+60') || value.startsWith('01')) {
        score += 10;
      }
      if (value.contains('000')) {
        score += 30;
        reasons.add('Frequently reported scam number pattern');
      }
      if (value.length < 9) {
        score += 20;
        reasons.add('Invalid phone number length');
      }
    }

    // 🏦 BANK ACCOUNT
    if (type == 'Bank Account') {
      if (value.length < 8) {
        score += 30;
        reasons.add('Invalid bank account length');
      }
      if (value.contains('999') || value.contains('000')) {
        score += 40;
        reasons.add('Pattern commonly reported in mule accounts');
      }
    }

    // 📄 DOCUMENT
    if (type == 'Document') {
      score += 40;
      reasons.add('Documents may contain hidden malicious content');
    }

    // Risk level
    String level;
    if (score >= 70) {
      level = 'high';
    } else if (score >= 40) {
      level = 'medium';
    } else {
      level = 'low';
    }

    int finalScore = score.clamp(0, 100);

    if (finalScore == 0 && reasons.isEmpty) {
      reasons.add('No risks detected');
    }

    return RiskResult(
      score: finalScore,
      level: level,
      reasons: reasons,
    );
  }

  // ── Private: heuristic URL analysis (runs offline) ──
  static RiskResult _heuristicUrlCheck(String url) {
    int score = 0;
    List<String> reasons = [];
    String lowerValue = url.toLowerCase();

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return RiskResult(
        score: 10,
        level: 'low',
        reasons: ['Content is not a valid URL or recognized format'],
      );
    }

    // Dangerous schemes
    final dangerousSchemes = ['javascript', 'vbs', 'file', 'data'];
    if (dangerousSchemes.contains(uri.scheme)) {
      return RiskResult(
        score: 100,
        level: 'high',
        reasons: ['Dangerous script or file execution detected (${uri.scheme}:)'],
      );
    }

    // Non-standard schemes
    final standardSchemes = ['http', 'https', 'mailto', 'tel', 'sms', 'geo'];
    if (uri.scheme.isNotEmpty && !standardSchemes.contains(uri.scheme)) {
      score += 20;
      reasons.add('Unusual link type detected (${uri.scheme})');
    }

    // Insecure HTTP
    if (uri.scheme == 'http') {
      score += 30;
      reasons.add('Insecure connection (HTTP instead of HTTPS)');
    }

    // Shortened URLs
    final shorteners = ['bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'is.gd', 'buff.ly', 'ow.ly'];
    if (shorteners.any((domain) => url.contains(domain))) {
      score += 40;
      reasons.add('URL shortener detected (often used to hide scams)');
    }

    // Suspicious keywords
    final suspiciousKeywords = [
      'login', 'verify', 'bank', 'secure', 'update', 'account',
      'reward', 'free', 'claim', 'bonus', 'gift', 'winner',
      'urgent', 'action', 'suspend', 'limited'
    ];

    int keywordCount = 0;
    for (var k in suspiciousKeywords) {
      if (lowerValue.contains(k)) {
        keywordCount++;
      }
    }

    if (keywordCount > 0) {
      score += 20 + (keywordCount * 10);
      reasons.add('Contains words commonly used in phishing ($keywordCount found)');
    }

    // Phishing patterns
    if (lowerValue.contains('ngrok') || lowerValue.contains('serveo')) {
      score += 80;
      reasons.add('Tunneling service detected (often used for phishing)');
    }
    if (url.contains('@')) {
      score += 50;
      reasons.add('URL contains "@" (often used to trick users)');
    }

    return RiskResult(score: score, level: 'low', reasons: reasons);
  }
}

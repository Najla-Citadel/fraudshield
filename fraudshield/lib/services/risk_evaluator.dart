import 'dart:developer';
import '../services/api_service.dart';

class RiskResult {
  final int score;
  final String level; // high, medium, low
  final List<String> reasons;
  final bool apiChecked; // Whether Safe Browsing API was consulted

  // Payment check specific fields
  final int communityReports;
  final int verifiedReports;
  final List<String> categories;
  final List<String> sources; // e.g. ['community', 'ccid']

  // Quishing specific fields
  final List<String> redirectChain;
  final String? finalUrl;
  final List<String> detectedBy;

  // NLP specific fields
  final String? scamType;
  final String? language;
  final List<String> matchedPatterns;
  final List<String> highlightedPhrases;

  // Document scan (PDF/APK) specific fields
  final List<String> extractedLinks; // URLs found embedded in PDF
  final String? packageName; // APK package name
  final List<String> dangerousPermissions; // APK dangerous permissions
  final int? pageCount; // PDF page count
  final String? sha256; // File fingerprint

  RiskResult({
    required this.score,
    required this.level,
    required this.reasons,
    this.apiChecked = false,
    this.communityReports = 0,
    this.verifiedReports = 0,
    this.categories = [],
    this.sources = [],
    this.redirectChain = [],
    this.finalUrl,
    this.detectedBy = [],
    this.scamType,
    this.language,
    this.matchedPatterns = [],
    this.highlightedPhrases = [],
    this.extractedLinks = [],
    this.packageName,
    this.dangerousPermissions = [],
    this.pageCount,
    this.sha256,
  });
}

class RiskEvaluator {
  static final ApiService _api = ApiService.instance;

  // ── Main entry point for URL checks (async, calls backend V2 engine) ──
  static Future<RiskResult> evaluateUrl(String url) async {
    int score = 0;
    List<String> reasons = [];
    bool apiChecked = false;

    // 1. Run local heuristic checks first (instant, offline fallback)
    final heuristic = _heuristicUrlCheck(url);
    score += heuristic.score;
    reasons.addAll(heuristic.reasons);

    // 2. Call V2 centralized risk engine (takes priority)
    try {
      final res = await _api.evaluateRisk(type: 'url', value: url);
      apiChecked = true;

      final int v2Score = (res['score'] as num?)?.toInt() ?? 0;
      final String level = res['level'] as String? ?? 'low';
      final List<dynamic> v2Reasons = res['reasons'] as List? ?? [];

      if (v2Score > score) {
        // V2 backend knows more — use its score and reasons
        score = v2Score;
        reasons =
            ['🤖 Community Intelligence Score'] + v2Reasons.cast<String>();
      }

      // Still apply Google Safe Browsing for URLs specifically
      try {
        final sbRes = await _api.checkUrl(url);
        if (sbRes['safe'] == false) {
          final threats = List<String>.from(sbRes['threats'] ?? []);
          score = ((score + 90) / 2).round().clamp(90, 100);
          for (final threat in threats) {
            switch (threat) {
              case 'SOCIAL_ENGINEERING':
                reasons.insert(
                    0, '⚠️ Phishing site detected by Google Safe Browsing');
                break;
              case 'MALWARE':
                reasons.insert(0,
                    '⚠️ Malware distribution detected by Google Safe Browsing');
                break;
              default:
                reasons.insert(
                    0, '⚠️ Flagged as $threat by Google Safe Browsing');
            }
          }
        } else if (v2Score < 30) {
          reasons.add('✅ Verified safe by Google Safe Browsing');
        }
      } catch (_) {
        // Safe Browsing failure is non-fatal
      }
    } catch (e) {
      log('V2 risk evaluation failed, falling back to local heuristics: $e');
      reasons.add('⚡ Could not reach community database (offline check only)');
    }

    // 3. Determine level from final score
    String level;
    if (score >= 80) {
      level = 'critical';
    } else if (score >= 55)
      level = 'high';
    else if (score >= 30)
      level = 'medium';
    else
      level = 'low';

    return RiskResult(
      score: score.clamp(0, 100),
      level: level,
      reasons: reasons,
      apiChecked: apiChecked,
    );
  }

  // ── New: Evaluate QR / Quishing (async, calls backend deep scan) ──
  static Future<RiskResult> evaluateQr(String payload) async {
    // 1. Run local heuristic for instant feedback
    final heuristic = _heuristicUrlCheck(payload);
    int score = heuristic.score;
    List<String> reasons = List.from(heuristic.reasons);
    bool apiChecked = false;

    // 2. Call backend deep scan
    try {
      final res = await _api.checkQr(payload);
      apiChecked = true;

      final int apiScore = (res['score'] as num?)?.toInt() ?? 0;
      final String apiLevel = res['level'] as String? ?? 'low';
      final List<dynamic> apiReasons = res['reasons'] as List? ?? [];
      final List<dynamic> chain = res['redirectChain'] as List? ?? [];
      final String? finalUrl = res['finalUrl'] as String?;
      final List<dynamic> detectedBy = res['detectedBy'] as List? ?? [];

      if (apiScore >= score) {
        score = apiScore;
        reasons = apiReasons.cast<String>();
      }

      return RiskResult(
        score: score.clamp(0, 100),
        level: apiLevel,
        reasons: reasons,
        apiChecked: apiChecked,
        redirectChain: chain.cast<String>(),
        finalUrl: finalUrl,
        detectedBy: detectedBy.cast<String>(),
      );
    } catch (e) {
      log('QR deep scan failed, falling back to heuristics: $e');
      reasons.add('⚡ Deep link analysis unavailable (offline check only)');

      String level = 'low';
      if (score >= 80) {
        level = 'critical';
      } else if (score >= 55)
        level = 'high';
      else if (score >= 30) level = 'medium';

      return RiskResult(
        score: score.clamp(0, 100),
        level: level,
        reasons: reasons,
        apiChecked: false,
      );
    }
  }

  // ── New: Analyze Message (NLP) ──
  static Future<RiskResult> analyzeMessage(String message) async {
    try {
      final res = await _api.analyzeMessage(message);

      return RiskResult(
        score: (res['score'] as num?)?.toInt() ?? 0,
        level: res['level'] as String? ?? 'low',
        reasons: (res['matchedPatterns'] as List? ?? []).cast<String>(),
        apiChecked: true,
        scamType: res['scamType'] as String?,
        language: res['language'] as String?,
        matchedPatterns: (res['matchedPatterns'] as List? ?? []).cast<String>(),
        highlightedPhrases:
            (res['highlightedPhrases'] as List? ?? []).cast<String>(),
      );
    } catch (e) {
      log('Message analysis failed: $e');
      return RiskResult(
        score: 0,
        level: 'low',
        reasons: ['⚡ Message analysis service is currently unavailable'],
        apiChecked: false,
      );
    }
  }

  // ── New: Evaluate Document (PDF/APK) ──
  static Future<RiskResult> evaluateDocument(String filePath) async {
    try {
      final ext = filePath.split('.').last.toLowerCase();
      final Map<String, dynamic> raw;

      if (ext == 'pdf') {
        raw = await _api.scanPdf(filePath);
      } else if (ext == 'apk') {
        raw = await _api.scanApk(filePath);
      } else {
        return RiskResult(
          score: 10,
          level: 'low',
          reasons: ['⚠️ Unsupported file type: .$ext'],
          apiChecked: false,
        );
      }

      // Both PdfScanResult and ApkScanResult share the same top-level envelope
      final data = raw['data'] as Map<String, dynamic>? ?? raw;

      return RiskResult(
        score: (data['score'] as num?)?.toInt() ?? 0,
        level: data['level'] as String? ?? 'low',
        reasons: (data['reasons'] as List? ?? []).cast<String>(),
        apiChecked: true,
        sha256: data['sha256'] as String?,

        // PDF-specific
        extractedLinks: (data['extractedLinks'] as List? ?? []).cast<String>(),
        pageCount: (data['metadata'] as Map?)
            ?.cast<String, dynamic>()['pageCount'] as int?,

        // APK-specific
        packageName: data['packageName'] as String?,
        dangerousPermissions:
            (data['dangerousPermissions'] as List? ?? []).cast<String>(),
      );
    } catch (e) {
      log('Document scan failed: $e');
      return RiskResult(
        score: 0,
        level: 'low',
        reasons: [
          '⚡ Document scan service is currently unavailable. Please try again.'
        ],
        apiChecked: false,
      );
    }
  }

  static Future<RiskResult> evaluatePayment({
    required String type, // "bank_account", "phone", "url"
    required String value,
  }) async {
    String cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    String backendType = type.toLowerCase();

    // Infer if it's phone or bank when generic 'Payment' is used
    if (type == 'Payment') {
      if (cleanValue.startsWith('+') ||
          cleanValue.startsWith('01') ||
          (cleanValue.length >= 9 && cleanValue.length <= 11)) {
        backendType = 'phone';
      } else {
        backendType = 'bank';
      }
    }

    // Run local heuristic for instant offline feedback while API loads
    String localType = backendType == 'phone'
        ? 'Phone No'
        : backendType == 'bank'
            ? 'Bank Account'
            : type;
    RiskResult localCheck = evaluate(type: localType, value: cleanValue);
    int score = localCheck.score;
    List<String> reasons = List.from(localCheck.reasons);

    int communityReports = 0;
    int verifiedReports = 0;
    List<String> categories = [];
    List<String> sources = [];
    String level = localCheck.level;

    // Call V2 centralized risk engine
    try {
      final res = await _api.evaluateRisk(type: backendType, value: cleanValue);

      final int v2Score = (res['score'] as num?)?.toInt() ?? 0;
      final List<dynamic> v2Reasons = res['reasons'] as List? ?? [];
      final Map<String, dynamic> factors =
          Map<String, dynamic>.from(res['factors'] ?? {});

      communityReports = (factors['communityReports'] as num?)?.toInt() ?? 0;
      verifiedReports = (factors['verifiedReports'] as num?)?.toInt() ?? 0;
      sources = communityReports > 0 ? ['community'] : [];

      if (v2Score > score) {
        // V2 backend has more info — use its score
        score = v2Score;
        reasons = v2Reasons.cast<String>();
      } else if (communityReports > 0) {
        // Merge community info even if score is similar
        for (final r in v2Reasons) {
          if (!reasons.contains(r)) reasons.add(r as String);
        }
      }
    } catch (e) {
      log('V2 payment risk evaluation failed: $e');
      // Fall through to local heuristic result
    }

    if (score >= 80) {
      level = 'critical';
    } else if (score >= 55)
      level = 'high';
    else if (score >= 30)
      level = 'medium';
    else
      level = 'low';

    // Remove generic fallback message if we have community data
    if (score > 0) reasons.remove('No risks detected');

    return RiskResult(
      score: score.clamp(0, 100),
      level: level,
      reasons: reasons,
      apiChecked: true,
      communityReports: communityReports,
      verifiedReports: verifiedReports,
      categories: categories,
      sources: sources,
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

  // ── New: Evaluate Neighbor Spoofing ──
  static RiskResult evaluateNeighborSpoofing({
    required String incomingNumber,
    required String? userPhoneNumber,
  }) {
    if (userPhoneNumber == null ||
        userPhoneNumber.isEmpty ||
        incomingNumber.isEmpty) {
      return RiskResult(score: 0, level: 'low', reasons: []);
    }

    final cleanIncoming = incomingNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanUser = userPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanIncoming.length < 5 || cleanUser.length < 5) {
      return RiskResult(score: 0, level: 'low', reasons: []);
    }

    int matchLength = 0;
    for (int i = 0; i < cleanIncoming.length && i < cleanUser.length; i++) {
      if (cleanIncoming[i] == cleanUser[i]) {
        matchLength++;
      } else {
        break;
      }
    }

    int score = 0;
    String level = 'low';
    List<String> reasons = [];

    // Assuming exact match means calling oneself or an error, we ignore it or treat it as suspicious.
    // Let's assume neighbor spoofing applies when they are similar but not identical.
    if (cleanIncoming == cleanUser) {
      // Technically spoofing own number, very suspicious
      score = 80;
      level = 'critical';
      reasons.add('Call appears to be from your own number (Spoofing)');
    } else if (matchLength >= 7) {
      score = 60;
      level = 'critical';
      reasons.add(
          'High similarity to your own number (Neighbor Spoofing pattern)');
    } else if (matchLength >= 6) {
      score = 40;
      level = 'medium';
      reasons.add('Moderate similarity to your own number');
    } else if (matchLength >= 5) {
      score = 20;
      level = 'low';
      reasons.add('Slight similarity to your own number');
    }

    return RiskResult(
      score: score,
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
        reasons: [
          'Dangerous script or file execution detected (${uri.scheme}:)'
        ],
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
    final shorteners = [
      'bit.ly',
      'tinyurl.com',
      'goo.gl',
      't.co',
      'is.gd',
      'buff.ly',
      'ow.ly'
    ];
    if (shorteners.any((domain) => url.contains(domain))) {
      score += 40;
      reasons.add('URL shortener detected (often used to hide scams)');
    }

    // Suspicious keywords
    final suspiciousKeywords = [
      'login',
      'verify',
      'bank',
      'secure',
      'update',
      'account',
      'reward',
      'free',
      'claim',
      'bonus',
      'gift',
      'winner',
      'urgent',
      'action',
      'suspend',
      'limited'
    ];

    int keywordCount = 0;
    for (var k in suspiciousKeywords) {
      if (lowerValue.contains(k)) {
        keywordCount++;
      }
    }

    if (keywordCount > 0) {
      score += 20 + (keywordCount * 10);
      reasons.add(
          'Contains words commonly used in phishing ($keywordCount found)');
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

class RiskResult {
  final int score;
  final String level; // high, medium, low
  final List<String> reasons;

  RiskResult({
    required this.score,
    required this.level,
    required this.reasons,
  });
}

class RiskEvaluator {
  static RiskResult evaluate({
    required String type,
    required String value,
  }) {
    int score = 0;
    List<String> reasons = [];
    String lowerValue = value.toLowerCase();

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

    // 🌐 URL / QR Code Content
    if (type == 'URL' || type == 'QR') {
      final uri = Uri.tryParse(value);
      
      // 1. Basic Validity
      if (uri == null) {
        return RiskResult(
           score: 10, 
           level: 'low', 
           reasons: ['Content is not a valid URL or recognized format']
        );
      }

      // 2. Dangerous Schemes
      final dangerousSchemes = ['javascript', 'vbs', 'file', 'data'];
      if (dangerousSchemes.contains(uri.scheme)) {
        return RiskResult(
          score: 100, 
          level: 'high', 
          reasons: ['Dangerous script or file execution detected (${uri.scheme}:)']
        );
      }

      // 3. Non-Standard Schemes (Warning)
      final standardSchemes = ['http', 'https', 'mailto', 'tel', 'sms', 'geo'];
      if (uri.scheme.isNotEmpty && !standardSchemes.contains(uri.scheme)) {
        score += 20;
        reasons.add('Unusual link type detected (${uri.scheme})');
      }

      // 4. Insecure HTTP
      if (uri.scheme == 'http') {
        score += 30;
        reasons.add('Insecure connection (HTTP instead of HTTPS)');
      }

      // 5. Shortened URLs (Explicit Check)
      final shorteners = ['bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'is.gd', 'buff.ly', 'ow.ly'];
      if (shorteners.any((domain) => value.contains(domain))) {
        score += 40; // Higher risk for shorteners in fraud context
        reasons.add('URL shortener detected (often used to hide scams)');
      } else if (uri.host.isNotEmpty && uri.host.length < 5 && !uri.host.contains('.')) {
         // Very short generic hosts
         score += 10;
         reasons.add('Short or unclear domain name');
      }

      // 6. Suspicious Keywords (Content Analysis)
      final suspiciousKeywords = [
        'login', 'verify', 'bank', 'secure', 'update', 'account', 
        'reward', 'free', 'claim', 'bonus', 'gift', 'winner', 
        'urgent', 'action', 'suspend', 'limited'
      ];
      
      /* 
         If a URL contains these words but isn't a known safe domain, 
         increase score. In a real app, we'd whitelist 'bankofamerica.com' etc.
         For now, we flag them if they appear in the path/query or subdomain
         to avoid flagging 'bank.com' (though even that is generic).
      */
      
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

      // 7. Phishing Patterns
      if (lowerValue.contains('ngrok') || lowerValue.contains('serveo')) {
         score += 80;
         reasons.add('Tunneling service detected (often used for phishing)');
      }
       if (value.contains('@')) {
         score += 50;
         reasons.add('URL contains "@" (often used to trick users)');
      }
    }

    // 🏦 BANK ACCOUNT (NEW)
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

    // 🔎 Risk level
    String level;
    if (score >= 70) {
      level = 'high';
    } else if (score >= 40) {
      level = 'medium';
    } else { // 0-39
      level = 'low';
    }

    // Cap score at 100
    int finalScore = score.clamp(0, 100);

    // If score is 0 but we want to be explicit it's safe
    if (finalScore == 0 && reasons.isEmpty) {
        reasons.add('No risks detected');
    }

    return RiskResult(
      score: finalScore,
      level: level,
      reasons: reasons,
    );
  }
}

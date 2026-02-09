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

    // 🌐 URL
    if (type == 'URL') {
      if (value.contains('bit.ly') || value.contains('tinyurl')) {
        score += 30;
        reasons.add('URL shortener detected');
      }
      if (!value.startsWith('https://')) {
        score += 20;
        reasons.add('Insecure website (not HTTPS)');
      }
      if (value.toLowerCase().contains('free') ||
          value.toLowerCase().contains('win')) {
        score += 20;
        reasons.add('Common phishing keywords found');
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
    } else {
      level = 'low';
    }

    return RiskResult(
      score: score.clamp(0, 100),
      level: level,
      reasons:
          reasons.isEmpty ? ['No known scam patterns detected'] : reasons,
    );
  }
}

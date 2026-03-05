import 'package:flutter_test/flutter_test.dart';
import 'package:fraudshield/services/risk_evaluator.dart';

void main() {
  group('RiskEvaluator QR/URL Tests', () {
    test('Safe HTTPS URL returns low risk', () {
      final result = RiskEvaluator.evaluate(type: 'URL', value: 'https://google.com');
      expect(result.level, 'low');
      expect(result.score, 0);
    });

    test('HTTP URL returns elevated risk', () {
      final result = RiskEvaluator.evaluate(type: 'URL', value: 'http://example.com');
      expect(result.score, greaterThan(0));
      expect(result.reasons, contains('Insecure connection (HTTP instead of HTTPS)'));
    });

    test('Dangerous scheme (javascript:) returns high risk', () {
      final result = RiskEvaluator.evaluate(type: 'QR', value: 'javascript:alert(1)');
      expect(result.level, 'high');
      expect(result.score, 100);
      expect(result.reasons.first, contains('Dangerous script'));
    });

    test('Suspicious keywords increase score', () {
      final result = RiskEvaluator.evaluate(type: 'URL', value: 'https://secure-login-update.com');
      expect(result.score, greaterThan(20));
      expect(result.reasons.any((r) => r.contains('words commonly used')), true);
    });

    test('URL Shortener returns medium/high risk', () {
      final result = RiskEvaluator.evaluate(type: 'URL', value: 'https://bit.ly/123');
      expect(result.score, greaterThanOrEqualTo(40));
      expect(result.reasons, contains('URL shortener detected (often used to hide scams)'));
    });

    test('Tunneling service (ngrok) returns high risk', () {
      final result = RiskEvaluator.evaluate(type: 'URL', value: 'https://xyz.ngrok.io');
      expect(result.level, 'high');
      expect(result.reasons, contains('Tunneling service detected (often used for phishing)'));
    });

    test('Invalid content handles gracefully', () {
      final result = RiskEvaluator.evaluate(type: 'QR', value: 'not-a-url');
      // "not-a-url" parses as path in Uri, scheme empty. 
      // It might trigger "Unusual link type" if scheme is empty? 
      // Let's check logic: if scheme empty, it falls through.
      // host might be empty.
      
      // Let's refine the test based on actual logic.
      // logic says: if uri == null -> low risk (invalid format).
      // "not-a-url" parses: scheme="", path="not-a-url".
      // scheme is empty, so "Non-Standard Schemes" check: unknown scheme.
      // Wait, standardSchemes check: `if (uri.scheme.isNotEmpty && !standardSchemes.contains(uri.scheme))`
      // So empty scheme is fine?
      // host length < 5? "not-a-url" has no host.
      
      expect(result.level, 'low'); // Should be safe or unknown, definitely not high.
    });
  });

  group('RiskEvaluator Phone Tests', () {
    test('Valid local mobile number', () {
      final result = RiskEvaluator.evaluate(type: 'Phone No', value: '012345678');
      // Starts with 01 -> +10 score (logic says `if (value.startsWith('+60') || value.startsWith('01')) score += 10;`)
      // Length > 8 -> OK.
      expect(result.score, 10); 
    });

    test('Scam pattern 000 returns high score', () {
      final result = RiskEvaluator.evaluate(type: 'Phone No', value: '0120001234');
      expect(result.score, greaterThanOrEqualTo(30));
      expect(result.reasons, contains('Frequently reported scam number pattern'));
    });
  });
}

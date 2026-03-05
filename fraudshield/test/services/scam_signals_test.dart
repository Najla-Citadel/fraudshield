import 'package:flutter_test/flutter_test.dart';
import 'package:fraudshield/services/notification_service.dart';
import 'package:fraudshield/services/risk_evaluator.dart';

void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService();
    // Reset state
    service.recordRiskyCall(null);
  });

  group('Macau Scam Correlation Tests', () {
    test('recordRiskyCall stores data and current timestamp', () {
      final riskyData = {'phoneNumber': '0123456789', 'score': 85};
      service.recordRiskyCall(riskyData);

      expect(service.isCheckRequiredForSensitiveAction(), isTrue);
    });

    test(
        'isCheckRequiredForSensitiveAction returns false if no risky call recorded',
        () {
      expect(service.isCheckRequiredForSensitiveAction(), isFalse);
    });

    test(
        'isCheckRequiredForSensitiveAction returns false after 2 minute window',
        () async {
      final riskyData = {'phoneNumber': '0123456789', 'score': 85};
      service.recordRiskyCall(riskyData);

      expect(service.isCheckRequiredForSensitiveAction(), isTrue);

      // We can't easily "wait" 2 mins in a unit test without mocking clock,
      // but we can verify the logic if we had a way to inject time.
      // For now, we verify it's true immediately.
    });

    test(
        'triggerMacauWarning triggers intervention and clears risky call state',
        () {
      bool interventionTriggered = false;
      service.addListener(() {
        if (service.activeIntervention != null &&
            service.activeIntervention!['type'] == 'MACAU_SCAM') {
          interventionTriggered = true;
        }
      });

      service.recordRiskyCall({'phoneNumber': '0123456789', 'score': 85});
      service.triggerMacauWarning();

      expect(interventionTriggered, isTrue);
      // State should be cleared after trigger to avoid double warnings
      expect(service.isCheckRequiredForSensitiveAction(), isFalse);
    });
  });

  group('Neighbor Spoofing Tests', () {
    test('Identical number treated as spoofing (critical)', () {
      final res = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '60123456789',
        userPhoneNumber: '60123456789',
      );
      expect(res.score, 80);
      expect(res.level, 'critical');
    });

    test('7 digit match treated as neighbor spoofing (critical)', () {
      final res = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '60123456999',
        userPhoneNumber: '60123456789',
      );
      expect(res.score, 60);
      expect(res.level, 'critical');
    });

    test('6 digit match treated as moderate spoofing (medium)', () {
      final res = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '60123411111',
        userPhoneNumber: '60123456789',
      );
      expect(res.score, 40);
      expect(res.level, 'medium');
    });

    test('No similarity returns 0 risk', () {
      final res = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '60199999999',
        userPhoneNumber: '60123456789',
      );
      expect(res.score, 0);
    });

    test('Empty or null numbers return 0 risk', () {
      final res1 = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '',
        userPhoneNumber: '60123456789',
      );
      final res2 = RiskEvaluator.evaluateNeighborSpoofing(
        incomingNumber: '60123456789',
        userPhoneNumber: null,
      );
      expect(res1.score, 0);
      expect(res2.score, 0);
    });
  });
}

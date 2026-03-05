import 'package:flutter_test/flutter_test.dart';
import 'package:fraudshield/services/notification_service.dart';

void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService();
    // Reset state before each test
    service.dismissCallerRisk();
    service.dismissIntervention();
    service.dismissPostCallCheck();
    service.dismissCoolDown();
  });

  group('NotificationService UX Extensibility', () {
    test('showPostCallCheck sets state and notifies listeners', () {
      bool notified = false;
      service.addListener(() => notified = true);

      final data = {'phoneNumber': '123', 'score': 60, 'level': 'high'};
      service.showPostCallCheck(data);

      expect(service.postCallCheck, data);
      expect(notified, isTrue);

      service.dismissPostCallCheck();
      expect(service.postCallCheck, isNull);
    });

    test('startCoolDown sets active state and end time', () {
      bool notified = false;
      service.addListener(() => notified = true);

      service.startCoolDown();

      expect(service.coolDownActive, isTrue);
      expect(service.coolDownEndsAt, isNotNull);
      // Ends at should be ~10 mins in the future
      final diff = service.coolDownEndsAt!.difference(DateTime.now());
      expect(diff.inMinutes, closeTo(10, 1)); // allow 1 min variance
      expect(notified, isTrue);

      service.dismissCoolDown();
      expect(service.coolDownActive, isFalse);
      expect(service.coolDownEndsAt, isNull);
    });
  });
}

import 'package:phone_state/phone_state.dart';
import 'notification_service.dart';

class CallStateService {
  static final CallStateService instance = CallStateService._internal();
  factory CallStateService() => instance;
  CallStateService._internal();

  void init() {
    PhoneState.stream.listen((event) {
      if (event.status.name.toUpperCase() == 'RINGING') {
        NotificationService.instance.showCallAlert();
      }
    });
  }
}

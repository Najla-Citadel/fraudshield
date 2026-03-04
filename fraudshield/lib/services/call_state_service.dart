import 'package:phone_state/phone_state.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'api_service.dart';

class CallStateService {
  static final CallStateService instance = CallStateService._internal();
  factory CallStateService() => instance;
  CallStateService._internal();

  DateTime? _callStartTime;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    debugPrint('CallStateService: Initializing...');

    // 1. Request Permissions
    final status = await Permission.phone.request();
    final notifStatus = await Permission.notification.request();

    debugPrint(
        'CallStateService: Permission status - Phone: $status, Notification: $notifStatus');

    if (status != PermissionStatus.granted) {
      debugPrint(
          'CallStateService: Phone permission NOT granted. Service will not work.');
      return;
    }

    // 2. Listen to Stream
    PhoneState.stream.listen((event) {
      final statusStr = event.status.name.toUpperCase();
      debugPrint(
          'CallStateService: event received. Status: $statusStr, Number: ${event.number}');

      if (statusStr == 'RINGING') {
        debugPrint('CallStateService: RINGING detected. Showing alert...');
        NotificationService.instance.showCallAlert();
        _reportSignal('CALL_START', number: event.number);
      } else if (statusStr == 'OFFHOOK') {
        debugPrint('CallStateService: OFFHOOK (Call Answered) detected.');
        _callStartTime = DateTime.now();
        _reportSignal('CALL_ACTIVE', number: event.number);
      } else if (statusStr == 'DISCONNECTED') {
        debugPrint('CallStateService: DISCONNECTED (Call Ended) detected.');
        int duration = 0;
        if (_callStartTime != null) {
          duration = DateTime.now().difference(_callStartTime!).inSeconds;
          _callStartTime = null;
        }
        _reportSignal('CALL_ENDED', duration: duration, number: event.number);
      }
    });

    _initialized = true;
    debugPrint('CallStateService: Initialized successfully.');
  }

  Future<void> _reportSignal(String type,
      {int? duration, String? number}) async {
    try {
      if (!ApiService.instance.isAuthenticated) return;

      await ApiService.instance.reportCallSignal(
        event: type,
        duration: duration,
        incomingNumber: number,
      );
      debugPrint('CallStateService: Reported $type to backend');
    } catch (e) {
      debugPrint('CallStateService: Failed to report $type: $e');
    }
  }
}

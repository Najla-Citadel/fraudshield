import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'api_service.dart';

class SmartCaptureService {
  static final SmartCaptureService _instance = SmartCaptureService._internal();
  factory SmartCaptureService() => _instance;
  SmartCaptureService._internal();

  bool _isStarted = false;
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  // List of Malaysian banking/payment app package names to monitor
  static const Set<String> _bankPackages = {
    'com.maybank2u.maybank2u', // MAE / Maybank
    'com.cimb.cimbclicks', // CIMB Clicks
    'com.tngdigital.ewallet', // TNG eWallet
    'com.hongleong.hlbconnect', // HLB Connect
    'com.rhbgroup.rhbnow', // RHB
    'com.pbebank.pbe', // Public Bank
    'com.citadel.fraudshield.v2', // For testing
  };

  Future<void> init() async {
    // No explicit background initialization needed for this plugin
  }

  Future<void> start() async {
    if (_isStarted) return;

    bool hasPermission =
        await NotificationListenerService.isPermissionGranted();
    if (!hasPermission) {
      debugPrint('SmartCaptureService: Permission not granted');
      return;
    }

    _isStarted = true;

    // Subscribe to notifications
    _subscription =
        NotificationListenerService.notificationsStream.listen(_handleEvent);
    debugPrint('SmartCaptureService: Notification listener started');
  }

  Future<void> stop() async {
    _subscription?.cancel();
    _isStarted = false;
    debugPrint('SmartCaptureService: Notification listener stopped');
  }

  void _handleEvent(ServiceNotificationEvent event) {
    debugPrint('SmartCaptureService: >>> New Event Received <<<');
    debugPrint('SmartCaptureService: Package: ${event.packageName}');
    debugPrint('SmartCaptureService: Title: ${event.title}');
    debugPrint('SmartCaptureService: Content: ${event.content}');
    debugPrint('SmartCaptureService: Id: ${event.id}');

    if (!_isStarted) {
      debugPrint('SmartCaptureService: Service NOT started, ignoring.');
      return;
    }

    // Check if the package is in our bank whitelist
    if (event.packageName == null ||
        !_bankPackages.contains(event.packageName)) {
      debugPrint(
          'SmartCaptureService: Package ${event.packageName} is not in whitelist. Ignoring.');
      return;
    }

    // Try multiple fields - text, title, or content
    final String? text = event.content ?? event.title;

    if (text == null) {
      debugPrint(
          'SmartCaptureService: Skipping - both content and title are null');
      return;
    }

    debugPrint(
        'SmartCaptureService: MATCHED BANK PACKAGE. Processing text: $text');

    _parseAndLog(text);
  }

  Future<void> _parseAndLog(String text) async {
    // Basic regex for Amount (RM XXX.XX)
    final RegExp amountRegExp =
        RegExp(r'RM\s?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
    final match = amountRegExp.firstMatch(text);

    if (match == null) return;

    String amountStr = match.group(1)!.replaceAll(',', '');
    double amount = double.parse(amountStr);

    // Extraction Logic: Determine if it's Money In or Out based on keywords
    bool isOutgoing = true;
    final lowText = text.toLowerCase();

    if (lowText.contains('received') ||
        lowText.contains('from') ||
        lowText.contains('credited')) {
      isOutgoing = false;
    }

    if (isOutgoing) {
      amount = -amount;
    }

    // Try to extract Recipient/Merchant (Very heuristic)
    String merchant = "Bank Transfer";
    if (text.contains('to ')) {
      merchant = text.split('to ').last;
    } else if (text.contains('paid ')) {
      merchant = text.split('paid ').last;
    } else if (text.contains('from ')) {
      merchant = text.split('from ').last;
    }

    // Truncate merchant if too long
    if (merchant.length > 30) {
      merchant = merchant.substring(0, 30).trim();
    }

    try {
      debugPrint('SmartCaptureService: EXECUTING logTransaction...');
      final response = await ApiService.instance.logTransaction(
        amount: amount,
        merchant: merchant,
        paymentMethod: 'DuitNow/Notification',
        platform: 'AUTO_CAPTURE',
        checkType: 'AUTO_CAPTURE',
        notes: 'Captured from notification: $text',
      );
      debugPrint(
          'SmartCaptureService: logTransaction SUCCESS! Response: $response');
    } catch (e) {
      debugPrint('SmartCaptureService: logTransaction FAILED: $e');
    }
  }

  /// Directly simulate parsing a notification text, bypassing the OS notification
  /// listener channel. Use this for test/debug flows where a real notification
  /// listener event won't arrive (e.g. emulators or same-app notifications).
  Future<void> simulateCapture(String text) async {
    debugPrint('SmartCaptureService: [SIMULATE] Directly parsing text: $text');
    await _parseAndLog(text);
  }

  static Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  static Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }
}

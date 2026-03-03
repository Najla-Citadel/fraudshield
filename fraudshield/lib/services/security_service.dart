import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  bool _isJailbroken = false;
  bool _developerMode = false;
  bool _isInitialized = false;

  bool get isJailbroken => _isJailbroken;
  bool get developerMode => _developerMode;
  bool get isSecure =>
      !_isJailbroken; // We can decide if developerMode should block too

  /// Initializes the security checks
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _isJailbroken = await FlutterJailbreakDetection.jailbroken;
      _developerMode = await FlutterJailbreakDetection.developerMode;

      if (kDebugMode) {
        debugPrint('🛡️ Security Check:');
        debugPrint('   - Jailbroken/Rooted: $_isJailbroken');
        debugPrint('   - Developer Mode: $_developerMode');
      }
    } catch (e) {
      debugPrint('❌ Security Check Failed: $e');
      // In case of error, assume the worst for production
      if (!kDebugMode) {
        _isJailbroken = true;
      }
    }

    _isInitialized = true;
  }

  /// Re-runs the check
  Future<bool> checkSecurity() async {
    _isInitialized = false;
    await init();
    return isSecure;
  }
}

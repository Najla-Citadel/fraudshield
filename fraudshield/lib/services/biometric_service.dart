import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class BiometricService {
  static final BiometricService instance = BiometricService._();
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._();

  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if the device is capable of biometric authentication
  Future<bool> isAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      log('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get the user's preference for biometric authentication
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Set the user's preference for biometric authentication
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Authenticate the user.
  /// [localizedReason] is the message shown to the user explaining why they need to authenticate.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 🛡️ Allows PIN/Pattern/Passcode fallback
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      log('Biometric authentication error: $e');
      return false;
    } catch (e) {
      log('Unknown biometric error: $e');
      return false;
    }
  }

  /// Helper to guard a sensitive action.
  /// Returns [true] if user is authenticated OR if biometrics are disabled by the user.
  Future<bool> guardAction({required String reason}) async {
    if (!await isEnabled()) return true;
    if (!await isAvailable()) return true;

    return await authenticate(localizedReason: reason);
  }
}

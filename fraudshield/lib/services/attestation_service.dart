import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class AttestationService {
  AttestationService._privateConstructor();
  static final AttestationService instance = AttestationService._privateConstructor();

  final ApiService _apiService = ApiService.instance;
  
  // Native Bridge
  static const _channel = MethodChannel('com.citadel.fraudshield/attestation');

  /// Full sequence to verify the app's integrity.
  /// Typically called during login or before sensitive transactions.
  Future<Map<String, dynamic>> runAttestationSequence() async {
    debugPrint('🛡️ AttestationService: Starting sequence...');
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('🛡️ AttestationService: Unsupported platform.');
        return {'isValid': true, 'message': 'Platform not supported for attestation'};
      }

      // 1. Get Nonce (Challenge) from the backend
      debugPrint('🛡️ AttestationService: Fetching nonce from backend...');
      final challengeData = await _apiService.get('/attestation/challenge');
      final String nonce = challengeData['nonce'];
      debugPrint('🛡️ AttestationService: Nonce received: $nonce');

      // 2. Obtain Token from Mobile OS SDK
      String? token;
      String platform = '';

      if (Platform.isAndroid) {
        platform = 'android';
        debugPrint('🛡️ AttestationService: Requesting Play Integrity token...');
        token = await _getAndroidIntegrityToken(nonce);
      } else if (Platform.isIOS) {
        platform = 'ios';
        debugPrint('🛡️ AttestationService: Requesting DeviceCheck token...');
        token = await _getIOSDeviceCheckToken(nonce);
      }

      if (token == null || token.isEmpty) {
        debugPrint('🛡️ AttestationService: TOKEN GENERATION FAILED.');
        return {'isValid': false, 'error': 'Could not generate integrity token'};
      }
      debugPrint('🛡️ AttestationService: Token obtained (length: ${token.length})');

      // 3. Submit for Verification
      debugPrint('🛡️ AttestationService: Submitting to backend for verification...');
      final verificationResult = await _apiService.post('/attestation/verify', {
        'platform': platform,
        'token': token,
        'nonce': nonce,
        if (Platform.isAndroid) 'packageName': 'com.citadel.fraudshield.v2',
      });

      debugPrint('🛡️ AttestationService: Verification result: $verificationResult');
      return verificationResult;
    } catch (e) {
      debugPrint('🛡️ AttestationService CRITICAL ERROR: $e');
      return {'isValid': false, 'error': e.toString()};
    }
  }

  Future<String?> _getAndroidIntegrityToken(String nonce) async {
    try {
      // Call native Android implementation
      final String token = await _channel.invokeMethod('getIntegrityToken', {
        'nonce': nonce,
        'cloudProjectNumber': "668317803810",
      });
      return token;
    } on PlatformException catch (e) {
      debugPrint('Native Integrity Error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Play Integrity Error: $e');
      return null;
    }
  }

  Future<String?> _getIOSDeviceCheckToken(String nonce) async {
    // Placeholder for native iOS implementation
    // On iOS, this would typically use AppAttestService
    return 'ios_mock_token_for_demo';
  }
}

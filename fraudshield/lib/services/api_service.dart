import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  // Secure storage — uses AES on Android (EncryptedSharedPreferences),
  // Keychain on iOS. Tokens are NEVER stored as plaintext.
  static final _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';

  // Migrate API_BASE_URL to compile-time variables.
  // Use --dart-define=API_BASE_URL=... at build time.
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  String? _token;
  String? _refreshToken;
  Future<bool>? _refreshFuture;

  // SHA-256 Fingerprint for api.fraudshieldprotect.com
  static const String _prodFingerprint =
      '71c19421bf024457a008b35ef53290f59e7b828cdbe1e4ef81ea29a8b3b8e9cd';

  // Backup fingerprint for certificate rotation (Primary replacement)
  static const String _backupFingerprint =
      '0000000000000000000000000000000000000000000000000000000000000000';

  Future<void> init() async {
    if (kDebugMode) {
      debugPrint('ApiService: Initialized with baseUrl: $baseUrl');
    }
    _token = await _secureStorage.read(key: _keyAuthToken);
    _refreshToken = await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<Map<String, dynamic>> getAppConfig() async {
    final response = await get('/config/app');
    return response as Map<String, dynamic>;
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> _setTokens(String? token, String? refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    if (token != null) {
      await _secureStorage.write(key: _keyAuthToken, value: token);
    } else {
      await _secureStorage.delete(key: _keyAuthToken);
    }
    if (refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    } else {
      await _secureStorage.delete(key: _keyRefreshToken);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        'X-FS-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'X-FS-Nonce': _generateNonce(),
      };

  String _generateNonce() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return random.hashCode.toString(); // Simple unique string for now
  }

  // ---------------- Auth ----------------

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? fullName,
    String? captchaToken,
  }) async {
    final data = await post('/auth/signup', {
      'email': email,
      'password': password,
      if (fullName != null) 'fullName': fullName,
      if (captchaToken != null) 'captchaToken': captchaToken,
    });

    await _setTokens(data['token'], data['refreshToken']);
    return data['user'];
  }

  Future<void> requestVerificationEmail() async {
    await post('/auth/request-verification', {});
  }

  Future<void> verifyEmail(String email, String otp) async {
    await post('/auth/verify-email', {
      'email': email,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> acceptTerms(String version) async {
    final data = await post('/auth/accept-terms', {
      'version': version,
    });
    return data['user'];
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final data = await post('/auth/login', {
      'email': email,
      'password': password,
    });

    await _setTokens(data['token'], data['refreshToken']);
    return data['user'];
  }

  Future<void> signOut() async {
    await _setTokens(null, null);
  }

  Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
    debugPrint('ApiService: signInWithGoogle calling POST /auth/google');
    try {
      final response = await post('/auth/google', {'idToken': idToken});
      debugPrint('ApiService: signInWithGoogle success');
      await _setTokens(response['token'], response['refreshToken']);
      return response;
    } catch (e) {
      debugPrint('ApiService: signInWithGoogle ERROR: $e');
      rethrow;
    }
  }

  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    // Deduplicate simultaneous refresh calls
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh() async {
    try {
      await _checkCertificatePinning();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _setTokens(data['token'], data['refreshToken']);
        if (kDebugMode) {
          debugPrint('ApiService: Token refreshed successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Token refresh failed (${response.statusCode})');
        }
        await signOut();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService refreshToken error: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await get('/auth/profile');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? bio,
    String? avatar,
    Map<String, dynamic>? metadata,
  }) async {
    return patch('/auth/profile', {
      if (fullName != null) 'fullName': fullName,
      if (bio != null) 'bio': bio,
      if (avatar != null) 'avatar': avatar,
      if (metadata != null) 'metadata': metadata,
    });
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    return post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await delete('/users/me');
  }

  Future<Map<String, dynamic>> getSecurityHealth() async {
    final response = await get('/users/security-health');
    return response as Map<String, dynamic>;
  }

  // ---------------- Admin ----------------

  Future<List<Map<String, dynamic>>> getAdminAlerts() async {
    final response = await get('/admin/alerts');
    return List<Map<String, dynamic>>.from(response);
  }

  // ==== Password Reset ====

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    return post('/auth/forgot-password', {'email': email});
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    return post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> getTransactionDetails(String txId) async {
    final response = await get('/admin/transactions/$txId');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> labelTransaction({
    required String txId,
    required String label,
    String? alertId,
  }) async {
    return post('/admin/label-transaction', {
      'txId': txId,
      'label': label,
      if (alertId != null) 'alertId': alertId,
    });
  }

  Future<Map<String, dynamic>> submitScamReport({
    required String type,
    required String category,
    required String description,
    String? target,
    bool isPublic = false,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? evidence,
  }) async {
    return post('/reports', {
      'type': type,
      'category': category,
      'description': description,
      'target': target,
      'isPublic': isPublic,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'evidence': evidence ?? {},
    });
  }

  Future<List<dynamic>> getMyReports() async {
    final response = await get('/reports/my');
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List;
    }
    return response as List;
  }

  Future<Map<String, dynamic>> getPublicFeed({
    double? lat,
    double? lng,
    double? radius,
    String? category,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (lat != null && lng != null && radius != null) {
      query += '&lat=$lat&lng=$lng&radius=$radius';
    }
    if (category != null && category.isNotEmpty) {
      query += '&category=${Uri.encodeComponent(category)}';
    }
    if (search != null && search.isNotEmpty) {
      query += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await get('/reports/public$query');

    if (response is Map<String, dynamic>) {
      return response;
    }

    // Fallback for unexpected formats
    return {
      'results': response is List ? response : [],
      'total': response is List ? response.length : 0,
      'hasMore': false,
    };
  }

  Future<Map<String, dynamic>> getReportDetails(String reportId) async {
    final response = await get('/reports/$reportId');
    return response as Map<String, dynamic>;
  }

  // ---------------- Community & Interaction (Phase 3) ----------------

  Future<List<dynamic>> getLeaderboard() async {
    final response = await get('/features/leaderboard');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMyRank() async {
    final response = await get('/features/leaderboard/me');
    return response as Map<String, dynamic>;
  }

  Future<List<dynamic>> getComments(String reportId) async {
    final response = await get('/reports/$reportId/comments');
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitComment({
    required String reportId,
    required String text,
  }) async {
    return post('/reports/comments', {
      'reportId': reportId,
      'text': text,
    });
  }

  Future<Map<String, dynamic>> searchReports({
    String? query,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minVerifications,
    String sortBy = 'newest',
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (category != null) 'category': category,
      if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      if (minVerifications != null && minVerifications > 0)
        'minVerifications': minVerifications.toString(),
      'sortBy': sortBy,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await get('/reports/search?$queryString');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyReport({
    required String reportId,
    required bool isSame,
  }) async {
    return post('/reports/verify', {
      'reportId': reportId,
      'isSame': isSame,
    });
  }

  // ---------------- Account & Ledger ----------------

  Future<Map<String, dynamic>> getTransactionJournal({
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (type != null) {
      query += '&type=$type';
    }

    final response = await get('/transactions$query');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJournalDetails(String journalId) async {
    final response = await get('/transactions/$journalId');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> logTransaction({
    required double amount,
    required String merchant,
    String? target,
    required String paymentMethod,
    required String platform,
    String? notes,
    String checkType = 'MANUAL',
  }) async {
    final response = await post('/transactions/log', {
      'amount': amount,
      'merchant': merchant,
      'target': target,
      'paymentMethod': paymentMethod,
      'platform': platform,
      'notes': notes,
      'checkType': checkType,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> convertToScamReport({
    required String journalId,
    required String description,
    required String category,
  }) async {
    final response = await post('/transactions/$journalId/report', {
      'description': description,
      'category': category,
    });
    return response as Map<String, dynamic>;
  }

  // ---------------- Subscriptions ----------------

  Future<List<dynamic>> getPlans() async {
    final response = await get('/features/plans');
    return response as List;
  }

  Future<Map<String, dynamic>> getMySubscription() async {
    final response = await get('/features/subscription');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSubscription({
    required String planId,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    return post('/features/subscription', {
      'planId': planId,
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
      'metadata': metadata ?? {},
    });
  }

  // ---------------- Points ----------------

  Future<Map<String, dynamic>> getMyPoints() async {
    final response = await get('/features/points');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addPoints({
    required int change,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    return post('/features/points', {
      'change': change,
      'reason': reason ?? '',
      'metadata': metadata ?? {},
    });
  }

  // ---------------- Behavioral Events ----------------

  Future<Map<String, dynamic>> logBehavioralEvent({
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    return post('/features/behavioral', {
      'type': type,
      'metadata': metadata ?? {},
    });
  }

  Future<List<dynamic>> getRecentEvents({int limit = 50}) async {
    final response = await get('/features/behavioral?limit=$limit');
    return response as List;
  }

  // ---------------- Alerts ----------------

  Future<List<dynamic>> getUserAlerts() async {
    final response = await get('/alerts');
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<void> markAlertsAsRead() async {
    await patch('/alerts/read-all', {});
  }

  Future<Map<String, dynamic>> resolveAlert(
      String alertId, String action) async {
    return await post('/alerts/$alertId/resolve', {'action': action});
  }

  // ---------------- Rewards ----------------

  Future<Map<String, dynamic>> getRewards() async {
    final response = await get('/rewards');
    if (response is List) {
      return {'results': response};
    }
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      return await post('/rewards/redeem', {'rewardId': rewardId});
    } catch (e) {
      // Re-throw with more specific error message
      throw Exception('Failed to redeem reward: $e');
    }
  }

  Future<List<dynamic>> getMyRedemptions() async {
    final response = await get('/rewards/redemptions');
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List;
    }
    return response as List;
  }

  Future<Map<String, dynamic>> getMyBadges() async {
    final response = await get('/features/badges');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claimDailyReward() async {
    return post('/rewards/daily', {});
  }

  // ---------------- Safe Browsing ----------------

  Future<Map<String, dynamic>> checkUrl(String url) async {
    return await post('/features/check-url', {'url': url});
  }

  // 2F: Advanced Link & QR (Quishing)
  Future<Map<String, dynamic>> checkLink(String url) async {
    return await post('/features/check-link', {'url': url});
  }

  Future<Map<String, dynamic>> checkQr(String payload) async {
    return await post('/features/check-qr', {'payload': payload});
  }

  // 2H: NLP-based Message Analysis
  Future<Map<String, dynamic>> analyzeMessage(String message) async {
    return await post('/features/analyze-message', {'message': message});
  }

  // 2E: PDF Document Scanning
  Future<Map<String, dynamic>> scanPdf(String filePath) async {
    return await _uploadFileToEndpoint(filePath, '/features/scan-pdf');
  }

  // 2G: APK & Malicious File Detection
  Future<Map<String, dynamic>> scanApk(String filePath) async {
    return await _uploadFileToEndpoint(filePath, '/features/scan-apk');
  }

  // Voice Scam Detection (Premium only)
  Future<Map<String, dynamic>> analyzeVoice(String filePath) async {
    return await _uploadFileToEndpoint(filePath, '/features/analyze-voice');
  }

  /// Upload in-memory audio bytes (from the record package).
  /// [bytes] = raw audio data, [filename] = e.g. 'recording.m4a'
  Future<Map<String, dynamic>> analyzeVoiceBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      await _checkCertificatePinning();
      final url = Uri.parse('$baseUrl/features/analyze-voice');
      final request = http.MultipartRequest('POST', url);

      final headersWithoutContentType = Map<String, String>.from(_headers)
        ..remove('Content-Type');
      request.headers.addAll(headersWithoutContentType);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
            body['message'] ?? 'Voice analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ApiService analyzeVoiceBytes error: $e');
      rethrow;
    }
  }

  /// Generic multipart file upload helper
  Future<Map<String, dynamic>> _uploadFileToEndpoint(
      String filePath, String endpoint) async {
    try {
      await _checkCertificatePinning();
      final url = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', url);

      // Copy auth headers (exclude Content-Type — multer sets it for multipart)
      final headersWithoutContentType = Map<String, String>.from(_headers)
        ..remove('Content-Type');
      request.headers.addAll(headersWithoutContentType);

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
            body['message'] ?? 'Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ApiService upload to $endpoint error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> lookupPaymentRisk({
    required String type,
    required String value,
  }) async {
    return await get('/reports/lookup?type=$type&value=$value');
  }

  // ---------------- AI Risk Score V2 ----------------

  /// Centralized risk evaluation. Replaces the old heuristic-only approach.
  /// [type] is one of: 'phone', 'bank', 'url', 'doc'
  Future<Map<String, dynamic>> evaluateRisk({
    required String type,
    required String value,
  }) async {
    return await post('/features/evaluate-risk', {
      'type': type,
      'value': value,
    });
  }

  // ---------------- Alerts ----------------

  Future<Map<String, dynamic>> getTrendingAlerts(
      {int hours = 72, double? lat, double? lng}) async {
    String query = '?hours=$hours';
    if (lat != null && lng != null) {
      query += '&lat=$lat&lng=$lng';
    }
    final response = await get('/alerts/trending$query');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDailyDigest() async {
    final response = await get('/alerts/daily-digest');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAlertPreferences() async {
    final response = await get('/alerts/preferences');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> subscribeToAlerts({
    List<String>? categories,
    double? latitude,
    double? longitude,
    int? radiusKm,
    String? fcmToken,
    bool? isActive,
    bool? emailDigestEnabled,
  }) async {
    return await post('/alerts/subscribe', {
      if (categories != null) 'categories': categories,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (isActive != null) 'isActive': isActive,
      if (emailDigestEnabled != null) 'emailDigestEnabled': emailDigestEnabled,
    });
  }

  // ---------------- CRUD Templates (for other features) ----------------

  Future<dynamic> get(String path) async {
    return _sendRequest('GET', path);
  }

  dynamic _processResponse(
    http.Response response,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    dynamic data;
    if (isJson) {
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint(
            'ApiService: Failed to decode JSON response: ${response.body}');
      }
    }

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return data ?? (response.body.isNotEmpty ? response.body : null);
    } else if (response.statusCode == 401 &&
        _refreshToken != null &&
        !path.contains('/auth/refresh')) {
      if (kDebugMode) {
        debugPrint(
            'ApiService: 401 Unauthorized for $path. Attempting refresh...');
      }

      final success = await refreshToken();
      if (success) {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Retrying $method $path after successful refresh');
        }
        return _sendRequest(method, path, body: body);
      }
      throw Exception('Session expired');
    } else {
      final message = isJson && data is Map
          ? (data['message'] ??
              (data['errors'] != null
                  ? (data['errors'] as List).map((e) => e['message']).join(', ')
                  : null))
          : response.body;
      throw Exception(
          message ?? '$method $path failed: ${response.statusCode}');
    }
  }

  Future<dynamic> _sendRequest(String method, String path,
      {Map<String, dynamic>? body}) async {
    try {
      await _checkCertificatePinning();

      final uri = Uri.parse('$baseUrl$path');
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http
              .post(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: _headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: _headers)
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Unsupported method: $method');
      }

      return _processResponse(response, method, path, body: body);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService $method $path error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final result = await _sendRequest('POST', path, body: body);
    return result is Map<String, dynamic> ? result : {'results': result};
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final result = await _sendRequest('PATCH', path, body: body);
    return result is Map<String, dynamic> ? result : {'results': result};
  }

  Future<dynamic> delete(String path) async {
    return _sendRequest('DELETE', path);
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      await _checkCertificatePinning();
      final url = Uri.parse('$baseUrl/upload/single');
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('File upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService uploadFile error: $e');
      }
      rethrow;
    }
  }

  /// Verifies the SSL certificate fingerprint for production API.
  /// Skips check if in development or not hitting the production domain.
  Future<void> _checkCertificatePinning() async {
    // Only enforce on production domain OR if explicitly requested in config
    final isProdDomain = baseUrl.contains('api.fraudshieldprotect.com');

    if (!isProdDomain) {
      if (kDebugMode) {
        debugPrint('ApiService: SSL Pinning skipped (non-production domain)');
      }
      return;
    }

    try {
      await HttpCertificatePinning.check(
        serverURL: baseUrl,
        headerHttp: {},
        sha: SHA.SHA256,
        allowedSHAFingerprints: [
          _prodFingerprint,
          _backupFingerprint, // Guard against rotation outage
        ],
        timeout: 10,
      );
      if (kDebugMode) {
        debugPrint('ApiService: SSL Pinning Verified Successfully');
      }
    } catch (e) {
      debugPrint('ApiService: SSL Pinning FAILED for $baseUrl: $e');
      rethrow; // Hard stop for security
    }
  }
}

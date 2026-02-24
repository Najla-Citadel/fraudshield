import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:flutter/foundation.dart'; // Added for kDebugMode if preferred, but debugPrint is enough.
import 'package:flutter/foundation.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();
  static const bool _isAndroidEmulator = true; // This could be determined dynamically if needed

  late final String baseUrl;
  String? _token;
  String? _refreshToken;

  Future<void> init() async {
    final String rawBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api/v1';
    
    // Use the .env value directly now that firewall is unblocked.
    // Sync-LocalIP.ps1 keeps this IP up to date with the machine's LAN IP.
    baseUrl = rawBaseUrl;

    if (kDebugMode) {
      debugPrint('ApiService: Initialized with baseUrl: $baseUrl');
    }
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> _setTokens(String? token, String? refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    } else {
      await prefs.remove('refresh_token');
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---------------- Auth ----------------

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final data = await post('/auth/signup', {
      'email': email,
      'password': password,
      if (fullName != null) 'fullName': fullName,
    });
    
    await _setTokens(data['token'], data['refreshToken']);
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

  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _setTokens(data['token'], data['refreshToken']);
        return true;
      } else {
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

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    return post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await delete('/users/me');
  }

  // ---------------- Admin ----------------

  Future<List<Map<String, dynamic>>> getAdminAlerts() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/alerts'), headers: _headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get alerts');
    }
  }

  // ==== Password Reset ====

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to request password reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService requestPasswordReset error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService resetPassword error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(String txId) async {
    final response = await http.get(Uri.parse('$baseUrl/admin/transactions/$txId'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get transaction details');
    }
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
      'latitude': latitude,
      'longitude': longitude,
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

  Future<List<dynamic>> getPublicFeed({
    double? lat,
    double? lng,
    double? radius,
    int limit = 20,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (lat != null && lng != null && radius != null) {
      query += '&lat=$lat&lng=$lng&radius=$radius';
    }
    final response = await get('/reports/public$query');
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List;
    }
    return response as List;
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
    final response = await http.get(Uri.parse('$baseUrl/features/subscription'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get subscription');
    }
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
    final response = await http
        .get(Uri.parse('$baseUrl/features/points'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get points');
    }
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

  // ---------------- Rewards ----------------

  Future<List<dynamic>> getRewards() async {
    final response = await get('/features/rewards');
    if (response is Map && response.containsKey('results')) {
      return response['results'] as List;
    }
    return response as List;
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      return await post('/features/rewards/redeem', {'rewardId': rewardId});
    } catch (e) {
      // Re-throw with more specific error message
      throw Exception('Failed to redeem reward: $e');
    }
  }

  Future<List<dynamic>> getMyRedemptions() async {
    final response = await get('/features/redemptions');
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

    return post('/features/rewards/daily', {});
  }

  // ---------------- Safe Browsing ----------------

  Future<Map<String, dynamic>> checkUrl(String url) async {
    return await post('/features/check-url', {'url': url});
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

  Future<Map<String, dynamic>> getTrendingAlerts({int hours = 72, double? lat, double? lng}) async {
    String query = '?hours=$hours';
    if (lat != null && lng != null) {
      query += '&lat=$lat&lng=$lng';
    }
    final response = await get('/alerts/trending$query');
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
  }) async {
    return await post('/alerts/subscribe', {
      if (categories != null) 'categories': categories,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (isActive != null) 'isActive': isActive,
    });
  }

  // ---------------- CRUD Templates (for other features) ----------------

  Future<dynamic> get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      
      return _processResponse(response, 'GET', path);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService GET error: $e');
      }
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response, String method, String path) async {
    final contentType = response.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json');

    dynamic data;
    if (isJson) {
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('ApiService: Failed to decode JSON response: ${response.body}');
        // Fallback or rethrow based on preference
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      return data ?? (response.body.isNotEmpty ? response.body : null);
    } else if (response.statusCode == 401 && _refreshToken != null && !path.contains('/auth/refresh')) {
      final success = await refreshToken();
      if (success) {
        // Retry logic is complex for multi-part or streaming, but simple for normal requests
        // For simplicity here, we re-run the request manually or via simplified logic
        // Recommendation: use a more robust interceptor approach if this grows.
      }
      throw Exception('Session expired');
    } else {
      final message = isJson && data is Map 
          ? (data['message'] ?? (data['errors'] != null ? (data['errors'] as List).map((e) => e['message']).join(', ') : null))
          : response.body;
      throw Exception(message ?? '$method $path failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      
      final result = await _processResponse(response, 'POST', path);
      return result is Map<String, dynamic> ? result : {'results': result};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService POST error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      
      final result = await _processResponse(response, 'PATCH', path);
      return result is Map<String, dynamic> ? result : {'results': result};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService PATCH error: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      
      return _processResponse(response, 'DELETE', path);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService DELETE error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
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
}

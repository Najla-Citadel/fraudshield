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
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> _setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
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
    final url = Uri.parse('$baseUrl/auth/signup');
    if (kDebugMode) {
      debugPrint('ApiService: POST $url');
    }

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              if (fullName != null) 'fullName': fullName,
            }),
          )
          .timeout(const Duration(seconds: 10)); // Force timeout after 10s
      
      if (kDebugMode) {
        debugPrint('ApiService: Response Status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _setToken(data['token']);
        return data['user'];
      } else {
        throw Exception('Signup failed: ${response.statusCode} - ${data['message'] ?? response.body}');
      }
    } catch (e, st) {
      print('ApiService signUp error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _setToken(data['token']);
        return data['user'];
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService signIn error: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _setToken(null);
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService getProfile error: $e');
      }
      rethrow;
    }
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
    return response as List;
  }

  Future<List<dynamic>> getPublicFeed() async {
    final response = await get('/reports/public');
    return response as List;
  }

  Future<Map<String, dynamic>> getReportDetails(String reportId) async {
    final response = await get('/reports/$reportId');
    return response as Map<String, dynamic>;
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
    final response = await http.get(Uri.parse('$baseUrl/features/points'), headers: _headers);
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
    return post('/features/check-url', {'url': url});
  }

  // ---------------- CRUD Templates (for other features) ----------------

  Future<dynamic> get(String path) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('GET $path failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService GET error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('POST $path failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService POST error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : {};
      } else {
        throw Exception('PATCH $path failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService PATCH error: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } else {
        throw Exception('DELETE $path failed: ${response.statusCode}');
      }
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

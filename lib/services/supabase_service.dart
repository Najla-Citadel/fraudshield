// lib/services/supabase_service.dart
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._privateConstructor();
  static final SupabaseService instance = SupabaseService._privateConstructor();

  /// Use the initialized client from main.dart -> Supabase.initialize(...)
  /// Make sure Supabase.initialize() runs before any call to this service.
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------- Auth ----------------

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      return res.user ?? _client.auth.currentUser;
    } catch (e, st) {
      log('signUp error: $e\n$st');
      rethrow;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      return res.user ?? _client.auth.currentUser;
    } catch (e, st) {
      log('signIn error: $e\n$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      log('signOut error: $e\n$st');
      rethrow;
    }
  }

  String? get currentUserId => _client.auth.currentUser?.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  void onAuthStateChange(void Function(AuthChangeEvent, Session?) handler) {
    _client.auth.onAuthStateChange.listen((data) {
      handler(data.event, data.session);
    });
  }

  // ---------------- Profiles ----------------

  Future<void> upsertProfile({
    required String userId,
    String? fullName,
    Map<String, dynamic>? extra,
  }) async {
    final payload = {
      'id': userId,
      if (fullName != null) 'full_name': fullName,
      if (extra != null) 'extra': extra,
    };

    try {
      // upsert without selecting (you can add .select().maybeSingle() if you want the returned row)
      await _client.from('profiles').upsert(payload);
    } catch (e, st) {
      log('upsertProfile error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (e, st) {
      log('getProfile error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- Behavioral Events ----------------

  Future<void> insertBehavioralEvent({
    required String userId,
    required String eventType,
    String? screenName,
    int? durationMs,
    Map<String, dynamic>? meta,
  }) async {
    final payload = {
      'user_id': userId,
      'event_type': eventType,
      'screen_name': screenName,
      'duration_ms': durationMs,
      if (meta != null) 'meta': meta,
    };

    try {
      await _client.from('behavioral_events').insert(payload).select();
    } catch (e, st) {
      log('insertBehavioralEvent error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- Transactions ----------------

  Future<Map<String, dynamic>> createTransaction({
    required String userId,
    required double amount,
    String? merchant,
    String? deviceId,
    Map<String, double>? geoLocation,
    Map<String, dynamic>? meta,
  }) async {
    final payload = {
      'user_id': userId,
      'amount': amount,
      if (merchant != null) 'merchant': merchant,
      if (deviceId != null) 'device_id': deviceId,
      if (geoLocation != null) 'geo_location': geoLocation,
      if (meta != null) 'meta': meta,
    };

    try {
      final row = await _client.from('transactions').insert(payload).select().single();
      return Map<String, dynamic>.from(row as Map);
    } catch (e, st) {
      log('createTransaction error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTransactionById(String txId) async {
    try {
      final row = await _client.from('transactions').select().eq('id', txId).maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (e, st) {
      log('getTransactionById error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- Helpers ----------------

  Future<List<Map<String, dynamic>>> recentBehavioralEvents({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final data = await _client.from('behavioral_events').select().eq('user_id', userId).order('created_at', ascending: false).limit(limit);
      final list = data as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      log('recentBehavioralEvents error: $e\n$st');
      rethrow;
    }
  }

  Future<void> dispose() async {
    // supabase_flutter does not require explicit client dispose
  }

  // ---------------- SUBSCRIPTIONS & PLANS ----------------

  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final res = await _client.from('subscription_plans').select().order('price', ascending: true);
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    } catch (e, st) {
      log('getPlans error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await _client
          .from('user_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      log('getMySubscription error: $e\n$st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> createSubscription({
    required String planId,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');

    final payload = {
      'user_id': uid,
      'plan_id': planId,
      'status': 'active',
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
      'metadata': metadata ?? {}
    };

    try {
      final row = await _client.from('user_subscriptions').insert(payload).select().maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (e, st) {
      log('createSubscription error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- POINTS ----------------

  /// Sum points from points_transactions for current user
  Future<int> getMyPoints() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final res = await _client.from('points_transactions').select('change').eq('user_id', uid);
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      int sum = 0;
      for (final row in list) {
        sum += (row['change'] ?? 0) as int;
      }
      return sum;
    } catch (e, st) {
      log('getMyPoints error: $e\n$st');
      rethrow;
    }
  }

  Future<void> addPoints({required int change, String? reason, Map<String, dynamic>? meta}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');
    try {
      await _client.from('points_transactions').insert({
        'user_id': uid,
        'change': change,
        'reason': reason ?? '',
        'meta': meta ?? {}
      });
    } catch (e, st) {
      log('addPoints error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> pointsHistory({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await _client.from('points_transactions').select().eq('user_id', uid).order('created_at', ascending: false).limit(limit);
      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      log('pointsHistory error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- SCAM REPORTS ----------------

  Future<Map<String, dynamic>?> createScamReport({
    required String reportType,
    required String category,
    required String description,
    String? phoneNumber,
    List<String>? evidenceUrls,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');

    final payload = {
      'user_id': uid,
      'report_type': reportType,
      'category': category,
      'description': description,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (evidenceUrls != null) 'evidence_urls': evidenceUrls,
      'status': 'pending',
    };

    try {
      final row = await _client.from('scam_reports').insert(payload).select().maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (e, st) {
      log('createScamReport error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyScamReports({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await _client.from('scam_reports').select().eq('user_id', uid).order('created_at', ascending: false).limit(limit);
      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      log('getMyScamReports error: $e\n$st');
      rethrow;
    }
  }

  // ---------------- FRAUD CHECKS ----------------

  Future<Map<String, dynamic>?> createFraudCheck({
    required String checkType,
    required String value,
    required int riskScore,
    required String riskLevel,
    required List<String> reasons,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not signed in');

    final payload = {
      'user_id': uid,
      'check_type': checkType,
      'value': value,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'reasons': reasons,
    };

    try {
      final row = await _client.from('fraud_checks').insert(payload).select().maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (e, st) {
      log('createFraudCheck error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyFraudChecks({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await _client.from('fraud_checks').select().eq('user_id', uid).order('created_at', ascending: false).limit(limit);
      return (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      log('getMyFraudChecks error: $e\n$st');
      rethrow;
    }
  }
}

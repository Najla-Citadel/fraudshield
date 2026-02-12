import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService.instance;
  bool _loading = true;
  UserModel? _user;
  Map<String, dynamic>? _subscription;

  AuthProvider() {
    _init();
  }

  bool get loading => _loading;
  UserModel? get user => _user;
  String? get userId => _user?.id;
  bool get isAuthenticated => api.isAuthenticated && _user != null;
  bool get isSubscribed => _subscription != null && (_subscription!['isActive'] == true || _subscription!['status'] == 'ACTIVE');

  /// Compatibility getter for screens expecting 'userProfile'
  UserModel? get userProfile => _user;

  Future<void> _init() async {
    try {
      await api.init();
      if (api.isAuthenticated) {
        await Future.wait([
          refreshProfile(),
          refreshSubscription(),
        ]);
        if (_user != null) {
          NotificationService.instance.initialize(_user!.id);
        }
      }
    } catch (e) {
      log('AuthProvider init error: $e');
      await api.signOut();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      final userData = await api.getProfile();
      _user = UserModel.fromJson(userData);
      notifyListeners();
    } catch (e) {
      log('AuthProvider refreshProfile error: $e');
      rethrow;
    }
  }

  Future<void> refreshSubscription() async {
    try {
      _subscription = await api.getMySubscription();
      notifyListeners();
    } catch (e) {
      log('AuthProvider subscription check: No active subscription or error ($e)');
      _subscription = null;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final userData = await api.signIn(email: email, password: password);
      _user = UserModel.fromJson(userData);
      NotificationService.instance.initialize(_user!.id);
      return true;
    } catch (e) {
      log('AuthProvider signIn error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final userData = await api.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _user = UserModel.fromJson(userData);
      NotificationService.instance.initialize(_user!.id);
      return true;
    } catch (e) {
      log('AuthProvider signUp error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await api.signOut();
    NotificationService.instance.clearAlerts();
    _user = null;
    _subscription = null;
    notifyListeners();
  }
}

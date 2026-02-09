import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService.instance;
  bool _loading = true;
  UserModel? _user;

  AuthProvider() {
    _init();
  }

  bool get loading => _loading;
  UserModel? get user => _user;
  String? get userId => _user?.id;
  bool get isAuthenticated => api.isAuthenticated && _user != null;

  /// Compatibility getter for screens expecting 'userProfile'
  UserModel? get userProfile => _user;

  Future<void> _init() async {
    try {
      await api.init();
      if (api.isAuthenticated) {
        await refreshProfile();
      }
    } catch (e) {
      log('AuthProvider init error: $e');
      // If token is invalid/expired, clear it
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

  Future<bool> signIn({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final userData = await api.signIn(email: email, password: password);
      _user = UserModel.fromJson(userData);
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
    _user = null;
    notifyListeners();
  }
}

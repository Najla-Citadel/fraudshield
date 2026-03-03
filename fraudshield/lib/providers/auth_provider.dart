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
<<<<<<< HEAD
  bool get isSubscribed => _subscription != null && (_subscription!['isActive'] == true || _subscription!['status'] == 'ACTIVE');
=======
  bool get isSubscribed =>
      _subscription != null &&
      (_subscription!['isActive'] == true ||
          _subscription!['status'] == 'ACTIVE');
>>>>>>> dev-ui2

  /// Compatibility getter for screens expecting 'userProfile'
  UserModel? get userProfile => _user;

<<<<<<< HEAD

=======
>>>>>>> dev-ui2
  Future<void> _init() async {
    try {
      await api.init();
      if (api.isAuthenticated) {
        log('AuthProvider: Token found, restoring session...');
        await Future.wait([
          refreshProfile(),
          refreshSubscription(),
        ]).catchError((e) {
          log('AuthProvider session restoration partial failure: $e');
          // If it's a "Session expired" message from ApiService, we should log out.
<<<<<<< HEAD
          // Otherwise, it might just be a network timeout, so we stay "authenticated" 
          // but with legacy/cached user data if available.
          if (e.toString().contains('Session expired') || e.toString().contains('401')) {
=======
          // Otherwise, it might just be a network timeout, so we stay "authenticated"
          // but with legacy/cached user data if available.
          if (e.toString().contains('Session expired') ||
              e.toString().contains('401')) {
>>>>>>> dev-ui2
            api.signOut();
          }
          return [];
        });
<<<<<<< HEAD
        
=======

>>>>>>> dev-ui2
        if (_user != null) {
          NotificationService.instance.initialize(_user!.id);
        }
      } else {
        log('AuthProvider: No token found.');
      }
    } catch (e) {
      log('AuthProvider init error: $e');
<<<<<<< HEAD
      // We don't call api.signOut() here because a network error 
=======
      // We don't call api.signOut() here because a network error
>>>>>>> dev-ui2
      // shouldn't wipe the user's saved tokens.
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

  Future<bool> signInWithGoogle(String idToken) async {
    debugPrint('AuthProvider: signInWithGoogle initiated');
    _loading = true;
    notifyListeners();
    try {
      debugPrint('AuthProvider: Sending token to backend...');
      final userData = await api.signInWithGoogle(idToken);
      debugPrint('AuthProvider: Backend successfully returned user data');
      _user = UserModel.fromJson(userData);
      NotificationService.instance.initialize(_user!.id);
      return true;
    } catch (e) {
      debugPrint('AuthProvider: error in signInWithGoogle: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
      debugPrint('AuthProvider: signInWithGoogle finished');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
<<<<<<< HEAD
=======
    String? captchaToken,
>>>>>>> dev-ui2
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final userData = await api.signUp(
        email: email,
        password: password,
        fullName: fullName,
<<<<<<< HEAD
=======
        captchaToken: captchaToken,
>>>>>>> dev-ui2
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
<<<<<<< HEAD
=======

  Future<void> acceptTerms(String version) async {
    try {
      final userData = await api.acceptTerms(version);
      _user = UserModel.fromJson(userData);
      notifyListeners();
    } catch (e) {
      log('AuthProvider acceptTerms error: $e');
      rethrow;
    }
  }
>>>>>>> dev-ui2
}

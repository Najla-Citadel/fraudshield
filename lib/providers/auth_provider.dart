import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService svc = SupabaseService.instance;
  bool _loading = true;
  String? _userId;

  AuthProvider() {
    _init();
  }

  bool get loading => _loading;
  String? get userId => _userId;
  bool get isAuthenticated => _userId != null;

  Future<void> _init() async {
    // ensure Supabase client already initialized in main()
    _userId = svc.currentUserId;
    _loading = false;
    notifyListeners();
    // subscribe to auth changes
    svc.onAuthStateChange((event, session) {
      _userId = svc.currentUserId;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      await svc.signIn(email: email, password: password);
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      await svc.signUp(email: email, password: password);
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> signOut() async {
    await svc.signOut();
    _userId = null;
    notifyListeners();
  }
}

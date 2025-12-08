import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final SupabaseService svc = SupabaseService.instance;

  // simple controllers for testing
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  String _log = '';
  Map<String, dynamic>? _lastTransaction;

  void _appendLog(String s) {
    setState(() => _log = '${DateTime.now().toIso8601String()} • $s\n\n$_log');
  }

  Future<void> _doSignUp() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _appendLog('SignUp: email or password empty');
      return;
    }
    try {
      final user = await svc.signUp(email: email, password: pass);
      _appendLog('SignUp success. userId=${user?.id ?? svc.currentUserId}');
      // optionally upsert profile
      if (svc.currentUserId != null) {
        await svc.upsertProfile(userId: svc.currentUserId!, fullName: 'Tester');
        _appendLog('Profile upserted');
      }
    } catch (e) {
      _appendLog('SignUp error: $e');
    }
  }

  Future<void> _doSignIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _appendLog('SignIn: email or password empty');
      return;
    }
    try {
      final user = await svc.signIn(email: email, password: pass);
      _appendLog('SignIn success. userId=${user?.id ?? svc.currentUserId}');
    } catch (e) {
      _appendLog('SignIn error: $e');
    }
  }

  Future<void> _insertEvent() async {
    final userId = svc.currentUserId;
    if (userId == null) {
      _appendLog('InsertEvent: no user logged in');
      return;
    }
    try {
      await svc.insertBehavioralEvent(
        userId: userId,
        eventType: 'tap_test',
        screenName: 'test_screen',
        durationMs: 120,
        meta: {'button': 'insertEvent'},
      );
      _appendLog('Behavioral event inserted for $userId');
    } catch (e) {
      _appendLog('InsertEvent error: $e');
    }
  }

  Future<void> _createTransaction() async {
    final userId = svc.currentUserId;
    if (userId == null) {
      _appendLog('CreateTx: no user logged in');
      return;
    }
    try {
      final row = await svc.createTransaction(
        userId: userId,
        amount: 123.45,
        merchant: 'Test Merchant',
        deviceId: 'emulator-1',
        geoLocation: {'lat': 3.1390, 'lon': 101.6869},
      );
      setState(() => _lastTransaction = row);
      _appendLog('Transaction created id=${row['id']} decision=${row['decision']} risk=${row['risk_score']}');
    } catch (e) {
      _appendLog('CreateTx error: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await svc.signOut();
      _appendLog('Signed out');
      setState(() => _lastTransaction = null);
    } catch (e) {
      _appendLog('SignOut error: $e');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ElevatedButton(onPressed: _doSignUp, child: const Text('Sign Up')),
            ElevatedButton(onPressed: _doSignIn, child: const Text('Sign In')),
            ElevatedButton(onPressed: _insertEvent, child: const Text('Insert Event')),
            ElevatedButton(onPressed: _createTransaction, child: const Text('Create Tx')),
            ElevatedButton(onPressed: _signOut, child: const Text('Sign Out')),
          ]),
          const SizedBox(height: 12),
          if (_lastTransaction != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Last Tx: id=${_lastTransaction!['id']}\ndecision=${_lastTransaction!['decision']}\nrisk=${_lastTransaction!['risk_score']}'),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: Text(_log))),
        ]),
      ),
    );
  }
}

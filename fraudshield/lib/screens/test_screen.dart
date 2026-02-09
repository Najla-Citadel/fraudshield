import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ApiService _api = ApiService.instance;

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
      final success = await context.read<AuthProvider>().signUp(
        email: email, 
        password: pass,
        fullName: 'Tester',
      );
      _appendLog('SignUp success: $success');
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
      final success = await context.read<AuthProvider>().signIn(
        email: email, 
        password: pass,
      );
      _appendLog('SignIn success: $success');
    } catch (e) {
      _appendLog('SignIn error: $e');
    }
  }

  Future<void> _insertEvent() async {
    try {
      await _api.post('/features/events', {
        'type': 'tap_test',
        'metadata': {'button': 'insertEvent'},
      });
      _appendLog('Behavioral event inserted');
    } catch (e) {
      _appendLog('InsertEvent error: $e');
    }
  }

  Future<void> _createTransaction() async {
    try {
      // Note: We don't have a direct 'createTransaction' endpoint for users in the current controller 
      // but we can test point adding as a proxy or use the admin labeling.
      final row = await _api.addPoints(change: 10, reason: 'Test points');
      setState(() => _lastTransaction = row);
      _appendLog('Points added: $row');
    } catch (e) {
      _appendLog('CreateTx error: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthProvider>().signOut();
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
                child: Text('Last Tx: id=${_lastTransaction!['id']}\ndecision=${_lastTransaction!['decision']}\nrisk=${_lastTransaction!['riskScore']}'),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: Text(_log))),
        ]),
      ),
    );
  }
}

// lib/screens/admin_alerts_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _alerts = [];
  bool _loading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final data = await _supabase
          .from('alerts')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _alerts = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alerts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _labelTx(String txId, String alertId, String label) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Insert label
      await _supabase.from('fraud_labels').insert({
        'tx_id': txId,
        'label': label,
        'labeled_by': user.id,
      });

      // Update alert
      await _supabase
          .from('alerts')
          .update({'processed': true})
          .eq('id', alertId);

      // Update UI
      setState(() {
        final idx = _alerts.indexWhere((a) => a['id'] == alertId);
        if (idx != -1) _alerts[idx]['processed'] = true;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Marked as $label')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _viewTransaction(String txId) async {
    try {
      final tx = await _supabase
          .from('transactions')
          .select()
          .eq('id', txId)
          .single();

      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Transaction ${tx['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Amount: ${tx['amount']}'),
              Text('Merchant: ${tx['merchant']}'),
              Text('Decision: ${tx['decision']}'),
              Text('Risk Score: ${tx['risk_score']}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final String txId = a['tx_id'] ?? '';
    final String alertId = a['id'] ?? '';
    final bool processed = a['processed'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TX: $txId', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Decision: ${a['decision']}'),
          Text('Risk Score: ${a['risk_score']}'),
          const SizedBox(height: 8),

          Row(children: [
            ElevatedButton(
              onPressed: () => _viewTransaction(txId),
              child: const Text('View'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: processed ? null : () => _labelTx(txId, alertId, 'fraud'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Fraud'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: processed ? null : () => _labelTx(txId, alertId, 'legit'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Legit'),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlerts,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(child: Text('No alerts yet'))
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView(
                    children: _alerts.map(_alertCard).toList(),
                  ),
                ),
    );
  }
}

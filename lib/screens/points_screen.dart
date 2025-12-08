// lib/screens/points_screen.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/supabase_service.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  bool _loading = true;
  int _balance = 0;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load(); // initial load
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      // load balance and history in parallel
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getMyPoints(),
        SupabaseService.instance.pointsHistory(limit: 50),
      ]);

      // results[0] is int, results[1] is List<Map<String,dynamic>>
      final int balance = results[0] as int;
      final List<Map<String, dynamic>> history =
          (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (!mounted) return;
      setState(() {
        _balance = balance;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load points: $e')));
    }
  }

  Future<void> _addPoints(int amount, {String reason = 'Bonus'}) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.addPoints(change: amount, reason: reason);
      // reload after successful addition
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points added')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add points: $e')));
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reward Points', style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                Text('$_balance', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                const Text('Available balance', style: TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _loading ? null : () => _addPoints(10, reason: 'Test bonus'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Earn +10'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final int change = (item['change'] ?? 0) as int;
    final String reason = (item['reason'] ?? '') as String;
    final String when = (item['created_at'] ?? '').toString();
    final bool positive = change >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: positive ? Colors.green[100] : Colors.red[100],
          child: Icon(positive ? Icons.add : Icons.remove, color: positive ? Colors.green : Colors.red),
        ),
        title: Text(reason.isNotEmpty ? reason : (positive ? 'Earned points' : 'Spent points')),
        subtitle: Text(when),
        trailing: Text(
          (positive ? '+' : '') + change.toString(),
          style: TextStyle(color: positive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _history.isEmpty
                          ? const Center(child: Text('No points history yet'))
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (_, i) => _buildHistoryItem(_history[i]),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

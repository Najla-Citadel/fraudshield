import 'dart:developer';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.getMyPoints();
      if (!mounted) return;
      setState(() {
        _history = List<Map<String, dynamic>>.from(res['transactions'] ?? []);
        _loading = false;
      });
    } catch (e) {
      log('Error loading history: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points History'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No history yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final item = _history[i];
                    final amount = item['amount'] as int;
                    final positive = amount >= 0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: positive
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: Icon(
                            positive ? Icons.add : Icons.remove,
                            color: positive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(item['description'] ?? ''),
                        subtitle:
                            Text(item['createdAt'].toString()),
                        trailing: Text(
                          '${positive ? '+' : ''}$amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: positive
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

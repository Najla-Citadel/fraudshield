import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _mySub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      // 1️⃣ Load all subscription plans
      final planRes = await supabase.from('subscription_plans').select();
      _plans = (planRes as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // 2️⃣ Load user's latest subscription
      final subRes = await supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (subRes.isNotEmpty) {
        _mySub = Map<String, dynamic>.from(subRes.first as Map<String, dynamic>);
      } else {
        _mySub = null;
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      final insertRes = await supabase.from('user_subscriptions').insert({
        'user_id': user.id,
        'plan_id': plan['id'],
        'status': 'active',
        'expires_at': expiresAt.toIso8601String(),
        'metadata': {'source': 'manual_test'}
      }).select();

      if (insertRes.isNotEmpty) {
        _mySub = Map<String, dynamic>.from(insertRes.first);
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Subscribed!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Subscribe failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final supabase = Supabase.instance.client;
    final userSubPlanId = _mySub?['plan_id'];

    final isCurrent = userSubPlanId == plan['id'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("RM ${plan['price']} / ${plan['billing_interval']}",
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),

          // Feature List
          if (plan['features'] is List)
            ...((plan['features'] as List)
                .map((f) => Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(f.toString()))
                      ],
                    ))
                .toList()),

          const SizedBox(height: 10),

          // Subscribe Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : () => _subscribe(plan),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: Text(isCurrent ? "Current Plan" : "Subscribe"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscription Plans"),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_mySub != null) ...[
                    Card(
                      child: ListTile(
                        title: Text("Active Plan"),
                        subtitle: Text(
                            "Plan ID: ${_mySub!['plan_id']}\nStatus: ${_mySub!['status']}\nExpires: ${_mySub!['expires_at']}"),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: ListView(
                      children: _plans.map(_planCard).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [];

  //final PageController _pageController =
  //    PageController(viewportFraction: 0.88);

  bool get hasActiveSub =>
      _activeSub != null && _activeSub!['status'] == 'active';

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadActiveSubscription();
  }

  // =========================
  // LOAD PLANS
  // =========================
  Future<void> _loadPlans() async {
    final res =
        await _supabase.from('subscription_plans').select().order('price', ascending: true);

    if (!mounted) return;
    setState(() => _plans = List<Map<String, dynamic>>.from(res));
  }

  // =========================
  // LOAD ACTIVE SUB
  // =========================
  Future<void> _loadActiveSubscription() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final res = await _supabase
        .from('user_subscriptions')
        .select('*, subscription_plans(name)')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (!mounted) return;
    setState(() => _activeSub = res);
  }

  // =========================
  // SUBSCRIBE (UNCHANGED)
  // =========================
  Future<void> _subscribe(Map<String, dynamic> plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await _supabase.from('user_subscriptions').insert({
        'user_id': user.id,
        'plan_id': plan['id'],
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated')),
      );

      await _loadActiveSubscription();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================
  // CANCEL (UNCHANGED)
  // =========================
  Future<void> _cancelSubscription() async {
    if (_activeSub == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('You will keep access until expiry.\n\nProceed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _supabase.from('user_subscriptions').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', _activeSub!['id']);

    await _loadActiveSubscription();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 🔹 ACTIVE SUB HEADER
          if (hasActiveSub) _activeHeader(),

          // 🔹 HERO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: const [
                Text(
                  'Upgrade Security',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Choose a protection tier to unlock advanced AI defenses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 🔹 PLANS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _plans.length,
              itemBuilder: (_, index) {
                final plan = _plans[index];

                return _ModernPlanCard(
                  plan: plan,
                  loading: _loading,
                  disabled:
                      hasActiveSub && _activeSub?['plan_id'] != plan['id'],
                  isCurrent: _activeSub?['plan_id'] == plan['id'],
                  onPressed: () => _subscribe(plan),
                );
              },
            ),
          ),

          // 🔹 CANCEL
          if (hasActiveSub)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _cancelSubscription,
                child: const Text(
                  'Cancel Subscription',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // ACTIVE HEADER
  // =========================
  Widget _activeHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Active Plan',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  _activeSub!['subscription_plans']['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Chip(
            label: Text('ACTIVE'),
            backgroundColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// MODERN PLAN CARD
////////////////////////////////////////////////////////////////

class _ModernPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onPressed;
  final bool isCurrent;
  final bool disabled;
  final bool loading;

  const _ModernPlanCard({
    required this.plan,
    required this.onPressed,
    required this.isCurrent,
    required this.disabled,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final color = plan['price'] == 0
        ? Colors.green
        : plan['price'] == 5.90
            ? AppColors.primaryBlue
            : Colors.orange;

    final isRecommended = plan['price'] == 5.90;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: disabled ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
            border: isRecommended ? Border.all(color: color, width: 2) : null,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                plan['name'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${plan['price']}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('/month', style: TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 16),
              ...(plan['features'] as List)
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (loading || disabled || isCurrent) ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Colors.grey : color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isCurrent
                        ? 'Current Plan'
                        : loading
                            ? 'Processing...'
                            : 'Activate Tier',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

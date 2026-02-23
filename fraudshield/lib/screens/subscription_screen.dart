import 'dart:ui';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_button.dart';
import '../constants/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _api = ApiService.instance;

  bool _loading = true;
  bool _isSubscribing = false;
  bool _isYearly = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'Basic',
      'price': 0,
      'features': ['Community Reports', 'AI SMS Blocking'],
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': 9.90,
      'priceYearly': 99.00,
      'features': ['Complete protection', 'Real-time alerts', 'Bank Verification', 'Priority Support'],
    },
  ];

  final PageController _pageController = PageController(viewportFraction: 0.88);

  // ── Getters ───────────────────────────────────────────
  bool get hasActiveSub => _activeSub != null && _activeSub!['status'] == 'ACTIVE';

  String get _expiryText {
    if (_activeSub == null) return '';
    try {
      final expiry = DateTime.parse(_activeSub!['expiresAt'].toString());
      return 'Renews on ${expiry.day}/${expiry.month}/${expiry.year}';
    } catch (_) {
      return 'Subscription active';
    }
  }

  // ── Data Loaders ─────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await Future.wait([_loadPlans(), _loadActiveSubscription()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPlans() async {
    try {
      final res = await _api.getPlans();
      if (!mounted) return;
      
      // Only override default plans if API returns valid data
      if (res.isNotEmpty) {
        setState(() => _plans = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      log('Error loading plans: $e');
      if (mounted) {
        setState(() {
          _plans = [
            {
              'id': 'free',
              'name': 'Basic',
              'price': 0,
              'features': ['Essential protection', 'Casual browsing'],
            },
            {
              'id': 'premium',
              'name': 'Premium',
              'price': 9.90,
              'priceYearly': 99.00,
              'features': ['Complete protection', 'Real-time alerts', 'Bank Verification', 'Priority Support'],
            }
          ];
        });
      }
    }
  }

  Future<void> _loadActiveSubscription() async {
    try {
      final res = await _api.getMySubscription();
      if (!mounted) return;
      setState(() => _activeSub = res);
    } catch (e) {
      if (mounted) setState(() => _activeSub = null);
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    if (plan['price'] == 0) return;

    setState(() => _isSubscribing = true);

    try {
      final duration = _isYearly ? const Duration(days: 365) : const Duration(days: 30);

      await _api.createSubscription(
        planId: plan['id'],
        expiresAt: DateTime.now().add(duration),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Welcome to Premium!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      await _loadActiveSubscription();
    } catch (e) {
      log('Error subscribing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -80, left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withOpacity(0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: hasActiveSub
                              ? _buildSubscriberView()
                              : _buildFreeUserView(),
                        ),
                      ),
                    ],
                  ),
          ),

          // Sticky Bottom Button (for free users only)
          if (!_loading && !hasActiveSub)
            Positioned(
              bottom: 24, left: 20, right: 20,
              child: _buildStickyButton(),
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FraudShield',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                  Text('PREMIUM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accentGreen, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Next-gen AI protection for your digital wealth.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── FREE USER VIEW ─────────────────────────────────────
  Widget _buildFreeUserView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildToggle(),
        const SizedBox(height: 28),
        SizedBox(
          height: 400,
          child: _plans.isEmpty
              ? Row(children: [_buildSkeletonCard(), _buildSkeletonCard()])
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _plans.length,
                  itemBuilder: (_, i) => _buildPlanCard(_plans[i]),
                ),
        ),
        const SizedBox(height: 36),
        _buildFeatureComparison(),
      ],
    );
  }

  // ── SUBSCRIBER VIEW ────────────────────────────────────
  Widget _buildSubscriberView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Premium Active Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 44),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You\'re a Premium Member!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  _expiryText,
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                ...([
                  'AI Real-time SMS Blocking',
                  'Bank Account Verification',
                  'Priority Threat Insights',
                  '24/7 Priority Support',
                ].map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18),
                      const SizedBox(width: 10),
                      Text(f, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Manage subscription
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manage Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Cancel or modify at any time', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureComparison(showActivePlan: true),
      ],
    );
  }

  // ── Components ─────────────────────────────────────────
  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Monthly', !_isYearly),
          _toggleBtn('Yearly', _isYearly, hasBadge: true),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool isActive, {bool hasBadge = false}) {
    return GestureDetector(
      onTap: () => setState(() => _isYearly = text == 'Yearly'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold, fontSize: 14,
              ),
            ),
            if (hasBadge && !isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(8)),
                child: const Text('SAVE 20%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isPremium = (plan['price'] as num) > 0;
    final bool isCurrent = hasActiveSub && _activeSub!['planId'] == plan['id'];

    double monthlyPrice = (plan['price'] as num).toDouble();
    double? yearlyTotal;

    if (_isYearly && isPremium) {
      yearlyTotal = (plan['priceYearly'] as num?)?.toDouble() ?? (monthlyPrice * 12 * 0.8);
      monthlyPrice = yearlyTotal / 12;
    }

    final priceStr = isPremium ? 'RM ${monthlyPrice.toStringAsFixed(2)}' : 'RM 0';
    final billingText = _isYearly && isPremium
        ? 'Billed RM ${yearlyTotal!.toStringAsFixed(2)} yearly'
        : 'Billed monthly';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(28),
        border: isPremium
            ? Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.white.withOpacity(0.06)),
        gradient: isPremium
            ? LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.accentGreen.withOpacity(0.07), Colors.transparent])
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'].toString().toUpperCase(),
                style: TextStyle(
                  color: isPremium ? AppColors.accentGreen : Colors.white54,
                  fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('POPULAR', style: TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Price
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: priceStr,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                ),
                TextSpan(
                  text: isPremium ? '/mo' : '',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16),
                ),
              ],
            ),
          ),
          if (isPremium) ...[
            const SizedBox(height: 4),
            Text(billingText, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Text(
            isPremium
                ? 'Complete AI-powered protection with real-time alerts.'
                : 'Basic protection for everyday use.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Current Plan', style: TextStyle(color: Colors.white54)),
                  )
                : ElevatedButton(
                    onPressed: isPremium ? () => _subscribe(plan) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? AppColors.accentGreen : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isPremium ? 'Get Premium' : 'Current Plan',
                      style: TextStyle(
                        color: isPremium ? Colors.black : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison({bool showActivePlan = false}) {
    final features = [
      _Feature('Community Reports', true, true),
      _Feature('AI Real-time SMS Blocking', true, true),
      _Feature('Bank Account Verification', false, true),
      _Feature('Priority Threat Insights', false, true),
      _Feature('QR Code Scan History', false, true),
      _Feature('24/7 Priority Support', false, true),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FEATURE COMPARISON',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          // Column Headers
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('FREE', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('PREMIUM', style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 4),
          ...features.map((f) => _featureRow(f.label, f.basic, f.premium, showActivePlan: showActivePlan)),
        ],
      ),
    );
  }

  Widget _featureRow(String label, bool basic, bool premium, {bool showActivePlan = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _checkIcon(basic, isPremium: false),
                _checkIcon(premium, isPremium: true, isHighlighted: showActivePlan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon(bool enabled, {bool isPremium = false, bool isHighlighted = false}) {
    if (!enabled) return Container(width: 20, height: 2, color: Colors.white.withOpacity(0.15));
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isPremium || isHighlighted) ? AppColors.accentGreen : Colors.transparent,
      ),
      child: Icon(Icons.check, size: 14,
        color: (isPremium || isHighlighted) ? Colors.black : Colors.white54),
    );
  }

  Widget _buildStickyButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: AppColors.accentGreen.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: AdaptiveButton(
        isLoading: _isSubscribing,
        onPressed: () {
          final premium = _plans.firstWhere((p) => (p['price'] as num) > 0, orElse: () => {});
          if (premium.isNotEmpty) _subscribe(premium);
        },
        text: 'Upgrade to Premium',
        icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black),
      ),
    );
  }
}

class _Feature {
  final String label;
  final bool basic;
  final bool premium;
  const _Feature(this.label, this.basic, this.premium);
}

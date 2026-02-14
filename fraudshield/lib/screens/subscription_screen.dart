import 'dart:ui';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../constants/colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _api = ApiService.instance;

  bool _loading = false;
  bool _isYearly = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [];
  
  // Page Controller for cards
  final PageController _pageController = PageController(viewportFraction: 0.85);

  bool get hasActiveSub =>
      _activeSub != null && _activeSub!['status'] == 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadActiveSubscription();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // =========================
  // DATA LOADING
  // =========================
  Future<void> _loadPlans() async {
    try {
      final res = await _api.getPlans();
      if (!mounted) return;
      setState(() => _plans = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      log('Error loading plans: $e');
      // Fallback mock data if API fails or is empty
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
              'price': 9.90, // Monthly
              'priceYearly': 99.00, // Yearly
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
      // log('No active subscription or error: $e');
      if (mounted) setState(() => _activeSub = null);
    }
  }

  // =========================
  // ACTIONS
  // =========================
  Future<void> _subscribe(Map<String, dynamic> plan) async {
    if (plan['price'] == 0) return; // Can't subscribe to free plan manually usually

    setState(() => _loading = true);

    try {
      // Calculate expiry based on toggle
      final duration = _isYearly ? const Duration(days: 365) : const Duration(days: 30);
      
      await _api.createSubscription(
        planId: plan['id'],
        expiresAt: DateTime.now().add(duration),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome to Premium!')),
      );

      await _loadActiveSubscription();
    } catch (e) {
      log('Error subscribing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================
  // UI BUILD
  // =========================
  // =========================
  // UI BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned(
            top: -100,
            left: -100,
             child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Header (Refactored to be part of body content but cleaner)
                _buildHeader(context),
                
                // 2. Content (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Toggle
                        _buildToggle(),

                        const SizedBox(height: 32),

                        // Plan Cards
                        SizedBox(
                          height: 420, // Height for cards
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _plans.isEmpty ? 2 : _plans.length, // Fallback to 2 for skeleton
                            itemBuilder: (context, index) {
                              if (_plans.isEmpty) return _buildSkeletonCard();
                              final plan = _plans[index];
                              return _buildPlanCard(plan); 
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Feature Comparison
                        _buildFeatureComparison(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Sticky Bottom Button
          Positioned(
            bottom: 30, // Floating slightly above bottom
            left: 20,
            right: 20,
            child: _buildStickyButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
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
                    Text(
                      'FraudShield',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'PREMIUM',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                 ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Next-gen AI protection for your digital wealth.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textLight.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

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
      child: Container(
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
                color: isActive ? Colors.black : AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (hasBadge && !isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SAVE 20%',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isPremium = plan['price'] > 0;
    final bool isCurrent = hasActiveSub && _activeSub!['planId'] == plan['id'];
    
    // Determine price display
    double monthlyPrice = (plan['price'] as num).toDouble();
    double? yearlyTotal;
    
    if (_isYearly && isPremium) {
       yearlyTotal = (plan['priceYearly'] as num?)?.toDouble() ?? (monthlyPrice * 12 * 0.8);
       monthlyPrice = yearlyTotal / 12;
    }
    
    String priceStr = isPremium ? '\$${monthlyPrice.toStringAsFixed(2)}' : '\$0';
    String billingText = _isYearly && isPremium 
        ? 'Billed \$${yearlyTotal!.toStringAsFixed(2)} yearly' 
        : 'Billed monthly';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(32),
        border: isPremium 
            ? Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.white.withOpacity(0.05)),
        gradient: isPremium 
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accentGreen.withOpacity(0.05),
                  Colors.transparent,
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan['name'].toString().toUpperCase(),
            style: TextStyle(
              color: isPremium ? AppColors.accentGreen : AppColors.textLight.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceStr,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/mo',
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isPremium)
            Text(
              billingText,
              style: TextStyle(color: AppColors.textLight.withOpacity(0.4), fontSize: 12),
            ),
          const SizedBox(height: 16),
          Text(
            isPremium 
                ? 'Complete protection with real-time AI security.'
                : 'Essential protection for casual browsing.',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const Spacer(),
          
          // Action Button inside card (Alternative to sticky, or state indicator)
          SizedBox(
            width: double.infinity,
            child: isCurrent 
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.textLight.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Current Plan', style: TextStyle(color: AppColors.textLight)),
                )
              : ElevatedButton(
                  onPressed: isPremium ? () {} : null, // If basic, it's usually current or default
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium ? AppColors.accentGreen : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    isPremium ? 'Select Premium' : 'Current Plan',
                    style: TextStyle(
                      color: isPremium ? Colors.black : AppColors.textLight.withOpacity(0.5),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.textLight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FEATURE COMPARISON',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _featureRow('AI Real-time SMS Blocking', true, true),
          _featureRow('Bank Account Verification', false, true),
          _featureRow('Priority Threat Insights', false, true),
          _featureRow('24/7 Support', false, true),
        ],
      ),
    );
  }

  Widget _featureRow(String label, bool basic, bool premium) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textLight.withOpacity(0.8), fontSize: 14),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _checkIcon(basic),
                const SizedBox(width: 24),
                _checkIcon(premium, isPremium: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon(bool enabled, {bool isPremium = false}) {
    if (!enabled) {
      return Container(width: 20, height: 2, color: AppColors.textLight.withOpacity(0.2));
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPremium ? AppColors.accentGreen : Colors.transparent,
      ),
      child: Icon(
        Icons.check, 
        size: 16, 
        color: isPremium ? Colors.black : AppColors.textLight.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStickyButton() {
    if (hasActiveSub && _activeSub!['planId'] == 'premium') return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AdaptiveButton(
        onPressed: () {
          // Find premium plan
          final premium = _plans.firstWhere((p) => (p['price'] as num) > 0, orElse: () => {});
          if (premium.isNotEmpty) {
            _subscribe(premium);
          }
        },
        text: 'Upgrade to Premium',
        icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black),
      ),
    );
  }
}



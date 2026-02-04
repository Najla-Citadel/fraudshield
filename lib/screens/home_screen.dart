// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/info_card.dart';
import '../widgets/core/section_header.dart';
import '../widgets/latest_news_widget.dart';

import 'subscription_screen.dart';
import 'points_screen.dart';
import 'account_screen.dart';
import 'fraud_check_screen.dart';
import 'scam_reporting_screen.dart';
import 'phishing_protection_screen.dart';
import 'voice_detection_screen.dart';
import 'qr_detection_screen.dart';
import 'awareness_tips_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() { _userName = 'User'; _loadingProfile = false; });
      return;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (row != null && (row['full_name'] as String?)?.trim().isNotEmpty == true) {
        _userName = row['full_name'];
      } else {
        _userName = user.email?.split('@').first ?? 'User';
      }
    } catch (e) {
      _userName = user.email?.split('@').first ?? 'User';
    }

    if (mounted) setState(() => _loadingProfile = false);
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(userName: _userName, loading: _loadingProfile),
          const SubscriptionScreen(),
          const PointsScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), label: 'Protect'),
          BottomNavigationBarItem(icon: Icon(Icons.stars_rounded), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final bool loading;

  const _HomeTab({required this.userName, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: AppSpacing.l,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('FraudShield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 GREETING
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading ? 'Hi there,' : 'Hi $userName,',
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay protected from online frauds.',
                        style: AppTypography.bodyM,
                      ),
                    ],
                  ),
                ),
                Lottie.asset(
                  'assets/animations/greeting_bot.json',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ⚡ QUICK ACTIONS HEADER
            const SectionHeader(title: 'Quick Actions', actionLabel: ''),

            const SizedBox(height: AppSpacing.s),

            // ⚡ QUICK GRID
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Check Fraud',
                    icon: Icons.search,
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FraudCheckScreen())),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Phishing',
                    icon: Icons.shield,
                    color: AppColors.accentPurple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhishingProtectionScreen())),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // 🛡️ SITUATIONS
            const SectionHeader(title: 'What just happened?', actionLabel: ''),
            const SizedBox(height: AppSpacing.s),

            InfoCard(
              title: 'Suspicious Call?',
              subtitle: 'Analyze voice patterns for scams',
              iconData: Icons.mic_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceDetectionScreen())),
            ),
            
            InfoCard(
              title: 'Received a QR?',
              subtitle: 'Scan safely for malicious links',
              iconData: Icons.qr_code_scanner_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRDetectionScreen())),
            ),

            InfoCard(
              title: 'Report a Scam',
              subtitle: 'Help the community stay safe',
              iconData: Icons.report_problem_rounded, // or custom asset
              isPrimary: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScamReportingScreen())),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 📰 NEWS
            const LatestNewsWidget(limit: 3),

            const SizedBox(height: AppSpacing.xl),

            // 💡 TIPS
            SectionHeader(
              title: 'Awareness', 
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AwarenessTipsScreen())),
            ),
            const SizedBox(height: AppSpacing.s),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                    child: Image.asset('assets/images/tip_image.png', width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'Tip of the day: Never share OTPs with anyone, even bank staff.',
                      style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/latest_news_widget.dart';
import 'fraud_check_screen.dart';
import 'phishing_protection_screen.dart';
import 'voice_detection_screen.dart';
import 'qr_detection_screen.dart';
import 'scam_reporting_screen.dart';
import 'awareness_tips_screen.dart';
import 'subscription_screen.dart';
import 'points_screen.dart';
import 'account_screen.dart';
import 'community_feed_screen.dart';
import '../widgets/adaptive_navigation.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_slide_route.dart';
import '../widgets/fade_in_list.dart';
import '../widgets/skeleton_loader.dart';

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
    
    // Listen for real-time alerts
    NotificationService.instance.addListener(_handleNewAlert);
  }

  void _handleNewAlert() {
    if (!mounted) return;
    final alerts = NotificationService.instance.alerts;
    if (alerts.isNotEmpty) {
      final latest = alerts.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(latest['title'] ?? 'Fraud Warning', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(latest['message'] ?? 'Suspicious activity detected'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () {
            // Future: Navigate to alert details
          }),
        ),
      );
    }
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_handleNewAlert);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    
    // AuthProvider already handles profile loading/refreshing
    if (authProvider.userProfile == null) {
      await authProvider.refreshProfile();
    }

    if (mounted) {
      setState(() {
        _userName = authProvider.userProfile?.fullName ?? 
                   authProvider.user?.email?.split('@').first ?? 
                   'User';
        _loadingProfile = false;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _loadProfile(); // refresh greeting
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            userName: _userName,
            loading: _loadingProfile,
          ),
          const CommunityFeedScreen(), // NEW
          const SubscriptionScreen(),
          const PointsScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: AdaptiveNavigation(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            activeIcon: Icon(Icons.subscriptions),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars_outlined),
            activeIcon: Icon(Icons.stars),
            label: 'Points',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// HOME TAB CONTENT (UI ONLY)
////////////////////////////////////////////////////////////////

class _HomeTab extends StatelessWidget {
  final String userName;
  final bool loading;

  const _HomeTab({
    required this.userName,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap entire HomeTab in AnimatedBackground for that premium feel
    return AnimatedBackground(
      child: AdaptiveScaffold(
        title: 'FraudShield',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: FadeInList(
            children: [
              // 👋 GREETING
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          loading 
                          ? const SkeletonLoader(width: 150, height: 36, borderRadius: 8)
                          : Text(
                              'Hi $userName 👋',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                        const SizedBox(height: 6),
                        loading
                          ? const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: SkeletonLoader(width: 200, height: 16, borderRadius: 4),
                            )
                          : const Text(
                              'Let’s keep your digital life safe today!',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 90,
                      child: Lottie.asset(
                        'assets/animations/greeting_bot.json',
                        repeat: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ⚡ QUICK ACTIONS
                const Text(
                  'What just happened?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _quickAction(
                      context,
                      'assets/icons/fraud_check.png',
                      'Fraud Check',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FraudCheckScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _quickAction(
                      context,
                      'assets/icons/shield.png',
                      'Phishing',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhishingProtectionScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _situationCard(
                  context,
                  imagePath: 'assets/icons/mic.png',
                  title: 'Someone called me',
                  subtitle: 'Check suspicious calls & voices',
                  onTap: () => Navigator.push(
                    context,
                    FadeSlideRoute(page: const VoiceDetectionScreen()),
                  ),
                  heroTag: 'hero_voice',
                ),

                _situationCard(
                  context,
                  imagePath: 'assets/icons/qr.png',
                  title: 'I received a QR',
                  subtitle: 'Scan QR codes safely',
                  onTap: () => Navigator.push(
                    context,
                    FadeSlideRoute(page: const QRDetectionScreen()),
                  ),
                  heroTag: 'hero_qr',
                ),

                _situationCard(
                  context,
                  imagePath: 'assets/icons/report.png',
                  title: 'I want to report a scam',
                  subtitle: 'Help protect others',
                  onTap: () => Navigator.push(
                    context,
                    FadeSlideRoute(page: const ScamReportingScreen()),
                  ),
                  heroTag: 'hero_report',
                ),

                const SizedBox(height: 20),
                const LatestNewsWidget(limit: 3),
                const SizedBox(height: 20),

                // 💡 AWARENESS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Awareness & Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AwarenessTipsScreen(),
                        ),
                      ),
                      child: const Text(
                        'Learn More',
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/tip_image.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Avoid clicking unknown links or downloading attachments from unverified sources.',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// SMALL REUSABLE WIDGETS
////////////////////////////////////////////////////////////////

Widget _quickAction(
  BuildContext context,
  String imagePath,
  String label,
  VoidCallback onTap,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Expanded(
    child: GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24),
      borderRadius: 20,
      child: Column(
        children: [
          Image.asset(imagePath, width: 32, height: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _situationCard(
  BuildContext context, {
  required String imagePath,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  required String heroTag,
  bool isPrimary = false,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassSurface(
      onTap: onTap,
      borderRadius: 20,
      child: Row(
        children: [
          Hero(
            tag: heroTag,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isPrimary
                  ? theme.cardColor
                  : (isDark ? Colors.white10 : Colors.grey.shade100),
              child: Image.asset(imagePath, width: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                     color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isPrimary
                ? theme.cardColor
                : theme.colorScheme.onSurface, // Fixed null check
          ),
        ],
      ),
    ),
  );
}

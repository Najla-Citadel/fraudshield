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
          const SubscriptionScreen(),
          const PointsScreen(),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).iconTheme.color,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions), label: 'Subscription'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
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
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 36),
          const SizedBox(width: 8),
          const Text(
            'FraudShield',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    ),

    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(188, 173, 201, 238), // top
            Color.fromARGB(223, 232, 235, 245), // bottom 
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 GREETING
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loading ? 'Hi' : 'Hi $userName 👋',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
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
                  MaterialPageRoute(
                    builder: (_) => const VoiceDetectionScreen(),
                  ),
                ),
              ),

              _situationCard(
                context,
                imagePath: 'assets/icons/qr.png',
                title: 'I received a QR',
                subtitle: 'Scan QR codes safely',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QRDetectionScreen(),
                  ),
                ),
              ),

              _situationCard(
                context,
                imagePath: 'assets/icons/report.png',
                title: 'I want to report a scam',
                subtitle: 'Help protect others',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScamReportingScreen(),
                  ),
                ),
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
  final bool isFraud = label == 'Fraud Check';
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isFraud
                ? [
                    const Color.fromARGB(255, 255, 255, 255),
                    const Color.fromARGB(255, 255, 255, 255),
                  ]
                : [
                    const Color.fromARGB(255, 255, 255, 255),
                    const Color.fromARGB(255, 255, 255, 255),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(imagePath, width: 28, height: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF222222),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
  bool isPrimary = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isPrimary
                  ? Theme.of(context).cardColor
                  : Colors.grey.shade100,
              child: Image.asset(imagePath, width: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isPrimary
                  ? Theme.of(context).cardColor
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ],
        ),
      ),
    ),
  );
}

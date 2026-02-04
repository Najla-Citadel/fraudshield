import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import '../constants/colors.dart';
import 'subscription_screen.dart';
import 'points_screen.dart';
import 'account_screen.dart';
import 'fraud_check_screen.dart';
import 'scam_reporting_screen.dart';
import 'phishing_protection_screen.dart';
import 'voice_detection_screen.dart';
import 'qr_detection_screen.dart';
import 'awareness_tips_screen.dart';
import '../widgets/latest_news_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _userName = 'User';
  bool _loadingProfile = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _userName = 'User';
        _loadingProfile = false;
      });
      return;
    }

    try {
      final row = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      // 🔹 If profile exists and name is valid
      if (row != null &&
          (row['full_name'] as String?)?.trim().isNotEmpty == true) {
        _userName = row['full_name'];
        print('Greeting username: $_userName');
      } else {
        // 🔹 Fallback to email prefix
        _userName = user.email?.split('@').first ?? 'User';

        // 🔹 OPTIONAL: auto-create / update profile
        await supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': _userName,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      _userName = user.email?.split('@').first ?? 'User';
    }

    if (mounted) {
      setState(() => _loadingProfile = false);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 GREETING
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    loading
                        ? const Text(
                            'Hi',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          )
                        : Text(
                            loading ? 'Hi' : 'Hi $userName,',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ],
                ),
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    'assets/animations/greeting_bot.json',
                    repeat: true,
                    animate: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),

            const Text(
              'Stay protected from online frauds.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 15),

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
                    MaterialPageRoute(builder: (_) => const FraudCheckScreen()),
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
                        builder: (_) => const PhishingProtectionScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📞 SITUATION CARDS
            _situationCard(
              context,
              imagePath: 'assets/icons/mic.png',
              title: 'Someone called me',
              subtitle: 'Check suspicious calls & voices',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceDetectionScreen()),
              ),
            ),

            _situationCard(
              context,
              imagePath: 'assets/icons/qr.png',
              title: 'I received a QR',
              subtitle: 'Scan QR codes safely',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRDetectionScreen()),
              ),
            ),

            _situationCard(
              context,
              imagePath: 'assets/icons/report.png',
              title: 'I want to report a scam',
              subtitle: 'Help protect others',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScamReportingScreen()),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AwarenessTipsScreen()),
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
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(imagePath, width: 26, height: 26),
            const SizedBox(height: 6),
            Text(label),
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
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
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
                      fontWeight: FontWeight.bold,
                      color: isPrimary
                          ? Theme.of(context).cardColor
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrimary
                          ? Theme.of(context).cardColor
                          : Theme.of(context).textTheme.bodyLarge!.color,
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

// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/colors.dart';
import 'account_screen.dart';
import 'fraud_check_screen.dart';
import 'scam_reporting_screen.dart';
import 'phishing_protection_screen.dart';
//import 'application_monitoring_screen.dart';
import 'voice_detection_screen.dart';
//import 'facial_detection_screen.dart';
import 'awareness_tips_screen.dart';
import 'admin_alerts_screen.dart';
import 'subscription_screen.dart';
import 'points_screen.dart';
import 'qr_detection_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'news_service.dart';
import '../widgets/latest_news_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // NEW: profile fields
  String _userName = 'User';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // NEW: loads profile from `profiles` table
  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _userName = 'User';
        _loadingProfile = false;
      });
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (row != null && (row['full_name'] as String?)?.trim().isNotEmpty == true) {
        setState(() {
          _userName = row['full_name'] as String;
          _loadingProfile = false;
        });
      } else {
        // fallback to email username part
        final email = user.email ?? '';
        final nickname = email.contains('@') ? email.split('@').first : 'User';
        setState(() {
          _userName = nickname;
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userName = 'User';
        _loadingProfile = false;
      });
    }
  }

  // UPDATED: await navigation and refresh profile when returning from Account
  void _onNavTap(int index) async {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    } else if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PointsScreen()),
      );
    } else if (index == 3) {
      // await and refresh profile after returning
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      );
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'FraudShield',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
            tooltip: 'Admin Alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAlertsScreen()),
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
            // 👋 Greeting + bot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // dynamic greeting
                    _loadingProfile
                        ? const Text(
                            'Hi...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          )
                        : Text(
                            'Hi $_userName,',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stay protected from online frauds.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                Image.asset('assets/images/hi_bot.png', height: 80),
              ],
            ),

            const SizedBox(height: 20),

            // 🧭 Grid menu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _featureCard(Icons.search, 'Fraud Checking', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FraudCheckScreen()));
                  }),
                  /*_featureCard(Icons.apps, 'Application Monitoring', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ApplicationMonitoringScreen()));
                  }),*/
                  _featureCard(Icons.report, 'Scam Reporting', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ScamReportingScreen()));
                  }),
                  _featureCard(Icons.mic, 'Voice Detection', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const VoiceDetectionScreen()));
                  }),
                  /*_featureCard(Icons.face, 'Facial Detection', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FacialDetectionScreen()));
                  }),*/
                  _featureCard(Icons.qr_code_scanner, 'QR Detection', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QRDetectionScreen()));
                  }),
                  _featureCard(Icons.shield, 'Phishing Monitoring', () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PhishingProtectionScreen()));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /* ⚠️ Latest Warning Section
            const Text(
              'Latest Warning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _warningCard('2', 'Suspicious\nTransaction', Icons.error_outline, Colors.orange),
                _warningCard('17', 'Suspicious\nPhone Number', Icons.phone, Colors.redAccent),
                _warningCard('6', 'Email\nBlocked', Icons.email, Colors.blueAccent),
              ],
            ),
            */

            // import at top of home_screen.dart


const SizedBox(height: 30),

const Text(
  'Latest Scam News',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 12),

FutureBuilder<List<NewsItem>>(
  future: NewsService.fetchFraudNews(limit: 6),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: SizedBox(height: 60, child: CircularProgressIndicator()));
    }
    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Failed to load news: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
            TextButton(
              onPressed: () {
                NewsService.clearCache();
                // trigger reload
                (context as Element).markNeedsBuild();
              },
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }
    final items = snapshot.data ?? [];
    if (items.isEmpty) {
      return const Text('No recent scam news found.');
    }

    return Column(
      children: items.map((n) {
        return GestureDetector(
          onTap: () async {
            final uri = Uri.tryParse(n.url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open article')));
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, size: 30, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    n.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      }).toList(),
    );
  },
),



            const SizedBox(height: 30),

            // 💡 Awareness & Tips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Awareness & Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AwarenessTipsScreen()),
                    );
                  },
                  child: const Text(
                    'Learn More',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/tip_image.png',
                        width: 70, height: 70, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Avoid clicking unknown links or downloading attachments from unverified sources.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'Subscription'),
          BottomNavigationBarItem(icon: Icon(Icons.stars), label: 'Points'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  // 🔹 Reusable Feature Card
  Widget _featureCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.lightBlue.withOpacity(0.6),
            child: Icon(icon, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 🔹 Warning Card
  Widget _warningCard(String count, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

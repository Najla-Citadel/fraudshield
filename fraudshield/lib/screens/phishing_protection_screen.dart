import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class PhishingProtectionScreen extends StatefulWidget {
  const PhishingProtectionScreen({super.key});

  @override
  State<PhishingProtectionScreen> createState() => _PhishingProtectionScreenState();
}

class _PhishingProtectionScreenState extends State<PhishingProtectionScreen> {
  bool isProtected = true; // Mock safe/unsafe toggle

  final List<Map<String, dynamic>> recentActivities = [
    {
      'url': 'www.bank-secure-update.com',
      'status': 'Suspicious',
      'date': '03 Nov 2025',
    },
    {
      'url': 'www.maybank2u.com.my',
      'status': 'Safe',
      'date': '02 Nov 2025',
    },
    {
      'url': 'sms: +60123456789',
      'status': 'Suspicious',
      'date': '01 Nov 2025',
    },
    {
      'url': 'www.lazada.com.my',
      'status': 'Safe',
      'date': '30 Oct 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Phishing Protection',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛡️ Header Section
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.blueAccent, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stay protected from fake websites, messages, and scams.',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 🟢 Status Card
            GlassCard(
              accentColor: isProtected ? Colors.green : Colors.redAccent,
              child: Column(
                children: [
                  Icon(
                    isProtected ? Icons.verified_user : Icons.warning_rounded,
                    color: isProtected ? Colors.green : Colors.redAccent,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isProtected ? 'You are Safe' : 'Suspicious Activity Detected!',
                    style: TextStyle(
                      color: isProtected ? Colors.green[800] : Colors.redAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isProtected
                        ? 'No phishing threat found recently.'
                        : 'Some phishing URLs were detected recently.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdaptiveButton(
                    onPressed: () {
                      setState(() {
                        isProtected = !isProtected;
                      });
                    },
                    text: isProtected ? 'Simulate Threat' : 'Back to Safe Mode',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🕓 Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),

            // 🧾 List of recent scans
            GlassCard(
              padding: EdgeInsets.zero,
              child: AnimationLimiter(
                child: Column(
                  children: recentActivities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSuspicious = item['status'] == 'Suspicious';
                    
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ListTile(
                            leading: Icon(
                              isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle,
                              color: isSuspicious ? Colors.redAccent : Colors.green,
                            ),
                            title: Text(
                              item['url'],
                              style: TextStyle(
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(item['date']),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSuspicious ? Colors.redAccent : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['status'],
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

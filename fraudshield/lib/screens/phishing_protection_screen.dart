import 'package:flutter/material.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/animated_background.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBackground(
      child: AdaptiveScaffold(
        title: 'Phishing Protection',
        backgroundColor: Colors.transparent, // Allow animated background to show
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🛡️ Header Section
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stay protected from fake websites, messages, and scams.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
  
              // 🟢 Status Card
              GlassSurface(
                accentColor: isProtected ? Colors.green : theme.colorScheme.error,
                child: Column(
                  children: [
                    Icon(
                      isProtected ? Icons.verified_user : Icons.warning_rounded,
                      color: isProtected ? Colors.green : theme.colorScheme.error,
                      size: 70,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isProtected ? 'You are Safe' : 'Suspicious Activity Detected!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isProtected ? Colors.green[800] : theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isProtected
                          ? 'No phishing threat found recently.'
                          : 'Some phishing URLs were detected recently.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AdaptiveButton(
                      onPressed: () {
                        setState(() {
                          isProtected = !isProtected;
                        });
                      },
                      text: isProtected ? 'Simulate Threat' : 'Back to Safe Mode',
                      // Optional: Make button style variant for threat mode?
                    ),
                  ],
                ),
              ),
  
              const SizedBox(height: 40),
  
              // 🕓 Recent Activity
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
  
              // 🧾 List of recent scans
              GlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: 20,
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
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Icon(
                                    isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle,
                                    color: isSuspicious ? theme.colorScheme.error : Colors.green,
                                  ),
                                  title: Text(
                                    item['url'],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    item['date'],
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSuspicious ? theme.colorScheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSuspicious ? theme.colorScheme.error.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      item['status'],
                                      style: TextStyle(
                                        color: isSuspicious ? theme.colorScheme.error : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index != recentActivities.length - 1)
                                  Divider(
                                    indent: 20, 
                                    endIndent: 20, 
                                    height: 1, 
                                    color: theme.colorScheme.outline.withOpacity(0.5)
                                  ),
                              ],
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
      ),
    );
  }
}

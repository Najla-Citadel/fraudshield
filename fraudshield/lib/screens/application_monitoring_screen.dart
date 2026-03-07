import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ApplicationMonitoringScreen extends StatefulWidget {
  const ApplicationMonitoringScreen({super.key});

  @override
  State<ApplicationMonitoringScreen> createState() => _ApplicationMonitoringScreenState();
}

class _ApplicationMonitoringScreenState extends State<ApplicationMonitoringScreen> {
  bool allSafe = true;

  final List<Map<String, dynamic>> apps = [
    {'name': 'MyBank App', 'status': 'Safe', 'package': 'com.mybank.app'},
    {'name': 'QuickLoanPro', 'status': 'Suspicious', 'package': 'com.quickloan.fake'},
    {'name': 'Grab', 'status': 'Safe', 'package': 'com.grab.app'},
    {'name': 'Shopee', 'status': 'Safe', 'package': 'com.shopee.app'},
    {'name': 'FastCashNow', 'status': 'Suspicious', 'package': 'com.fastcash.malware'},
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'App Security',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),

            // 🧭 Header
            Text(
              'Keep your device apps safe from risky applications.',
              style: TextStyle(
                fontSize: 16,
                color: DesignTokens.colors.textLight.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // 🟢 Status Overview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(DesignTokens.spacing.xl),
              decoration: BoxDecoration(
                color: (allSafe ? DesignTokens.colors.accentGreen : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                border: Border.all(
                  color: (allSafe ? DesignTokens.colors.accentGreen : Colors.red).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                   Icon(
                    allSafe ? LucideIcons.shieldCheck : LucideIcons.alertTriangle,
                    color: allSafe ? DesignTokens.colors.accentGreen : Colors.red,
                    size: 70,
                  ),
                  SizedBox(height: 10),
                  Text(
                    allSafe ? 'All Applications Safe' : 'Some Apps are Risky!',
                    style: TextStyle(
                      color: allSafe ? DesignTokens.colors.accentGreen : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    allSafe
                        ? 'No threats detected in installed apps.'
                        : 'Please review the suspicious apps below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  AppButton(
                    onPressed: () {
                      setState(() {
                        allSafe = !allSafe;
                      });
                    },
                    label: allSafe ? 'Simulate Threat' : 'Mark All Safe',
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),

            // 📊 Summary Section
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DesignTokens.colors.textLight,
              ),
            ),
            SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard('Total Apps', apps.length.toString(), LucideIcons.layoutGrid),
                _summaryCard('Safe', apps.where((a) => a['status'] == 'Safe').length.toString(), LucideIcons.shieldCheck),
                _summaryCard('Risky', apps.where((a) => a['status'] == 'Suspicious').length.toString(), LucideIcons.alertTriangle),
              ],
            ),

            SizedBox(height: 40),

            // 📱 List of Monitored Apps
            Text(
              'Monitored Apps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DesignTokens.colors.textLight,
              ),
            ),
            SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: Column(
                children: apps.map((app) {
                  final isSuspicious = app['status'] == 'Suspicious';
                  return ListTile(
                    leading: Icon(
                      isSuspicious ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
                      color: isSuspicious ? Colors.red : DesignTokens.colors.accentGreen,
                    ),
                    title: Text(
                      app['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      app['package'],
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isSuspicious ? Colors.red : DesignTokens.colors.accentGreen).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                        border: Border.all(color: (isSuspicious ? Colors.red : DesignTokens.colors.accentGreen).withOpacity(0.3)),
                      ),
                      child: Text(
                        app['status'],
                        style: TextStyle(
                          color: isSuspicious ? Colors.red : DesignTokens.colors.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Reusable small card for summary stats
  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xs),
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: DesignTokens.colors.primary),
            SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

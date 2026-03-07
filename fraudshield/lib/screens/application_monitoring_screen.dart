import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';

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
    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundLight,
      appBar: AppBar(
        backgroundColor: DesignTokens.colors.primary,
        title: Text(
          'Application Monitoring',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),

            // 🟢 Status Overview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(DesignTokens.spacing.xl),
              decoration: BoxDecoration(
                color: allSafe ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                border: Border.all(
                  color: allSafe ? Colors.green : Colors.redAccent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    allSafe ? Icons.verified_user : Icons.warning_rounded,
                    color: allSafe ? Colors.green : Colors.redAccent,
                    size: 70,
                  ),
                  SizedBox(height: 10),
                  Text(
                    allSafe ? 'All Applications Safe' : 'Some Apps are Risky!',
                    style: TextStyle(
                      color: allSafe ? Colors.green[800] : Colors.redAccent,
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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard('Total Apps', apps.length.toString(), Icons.apps),
                _summaryCard('Safe', apps.where((a) => a['status'] == 'Safe').length.toString(), Icons.check_circle),
                _summaryCard('Suspicious', apps.where((a) => a['status'] == 'Suspicious').length.toString(), Icons.warning_amber_rounded),
              ],
            ),

            SizedBox(height: 40),

            // 📱 List of Monitored Apps
            Text(
              'Monitored Apps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
              ),
              child: Column(
                children: apps.map((app) {
                  final isSuspicious = app['status'] == 'Suspicious';
                  return ListTile(
                    leading: Icon(
                      isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: isSuspicious ? Colors.redAccent : Colors.green,
                    ),
                    title: Text(
                      app['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      app['package'],
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSuspicious ? Colors.redAccent : Colors.green,
                        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                      ),
                      child: Text(
                        app['status'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
          boxShadow: DesignTokens.shadows.sm,
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
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

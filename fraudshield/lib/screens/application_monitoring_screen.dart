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
        title: const Text(
          'Application Monitoring',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 🧭 Header
            Text(
              'Keep your device apps safe from risky applications.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // 🟢 Status Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: allSafe ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 10),
                  Text(
                    allSafe ? 'All Applications Safe' : 'Some Apps are Risky!',
                    style: TextStyle(
                      color: allSafe ? Colors.green[800] : Colors.redAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allSafe
                        ? 'No threats detected in installed apps.'
                        : 'Please review the suspicious apps below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
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

            const SizedBox(height: 40),

            // 📊 Summary Section
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard('Total Apps', apps.length.toString(), Icons.apps),
                _summaryCard('Safe', apps.where((a) => a['status'] == 'Safe').length.toString(), Icons.check_circle),
                _summaryCard('Suspicious', apps.where((a) => a['status'] == 'Suspicious').length.toString(), Icons.warning_amber_rounded),
              ],
            ),

            const SizedBox(height: 40),

            // 📱 List of Monitored Apps
            Text(
              'Monitored Apps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSuspicious ? Colors.redAccent : Colors.green,
                        borderRadius: BorderRadius.circular(12),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: DesignTokens.colors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
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

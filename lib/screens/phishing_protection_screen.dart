import 'package:flutter/material.dart';
import '../constants/colors.dart';

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
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Phishing Protection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isProtected ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isProtected ? Colors.green : Colors.redAccent,
                  width: 1.5,
                ),
              ),
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
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isProtected = !isProtected;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isProtected ? 'Simulate Threat' : 'Back to Safe Mode',
                      style: const TextStyle(color: Colors.white),
                    ),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: recentActivities.map((item) {
                  final isSuspicious = item['status'] == 'Suspicious';
                  return ListTile(
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
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Privacy Policy',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: March 5, 2026',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. General Principle',
              'We obtain your explicit consent before collecting and processing your personal data. By registering an account, you consent to the processing of your data as described in this policy.',
            ),
            _buildSection(
              '2. Notice and Choice Principle',
              'We collect data to provide fraud protection services, improve security algorithms, and communicate alerts. Specifically for our Caller ID Protection feature, we collect and process your Phone State and Call Logs in real-time to identify potential scam numbers.',
            ),
            _buildSection(
              '3. Disclosure Principle',
              'We do not sell your personal data. We only disclose data to third-party service providers (e.g., cloud hosting, security verifiers) necessary for our operations, or when required by law.',
            ),
            _buildSection(
              '4. Security Principle',
              'We implement industry-standard encryption (AES-256) and security protocols to prevent unauthorized access, alteration, or disclosure of your personal data.',
            ),
            _buildSection(
              '5. Retention Principle',
              'We retain your personal data only for as long as necessary to fulfill the purposes of fraud protection or comply with legal, accounting, or reporting requirements.',
            ),
            _buildSection(
              '6. Data Integrity Principle',
              'We strive to maintain accurate and up-to-date data. You are encouraged to update your information through the Profile section to ensure its accuracy.',
            ),
            _buildSection(
              '7. Access Principle',
              'Under PDPA 2010, you have the right to access and correct your personal data. You can manage this through the "Privacy Settings" in your Account tab.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              height: 1.6,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

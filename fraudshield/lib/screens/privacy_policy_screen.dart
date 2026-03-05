import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Privacy Policy',
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: March 5, 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              '1. General Principle',
              'We obtain your explicit consent before collecting and processing your personal data. By registering an account, you consent to the processing of your data as described in this policy.',
            ),
            _buildSection(
              context,
              '2. Notice and Choice Principle',
              'We collect data to provide fraud protection services, improve security algorithms, and communicate alerts. Specifically for our Caller ID Protection feature, we collect and process your Phone State and Call Logs in real-time to identify potential scam numbers. You can choose not to provide certain data, though this may limit functionality.',
            ),
            _buildSection(
              context,
              '3. Disclosure Principle',
              'We do not sell your personal data. We only disclose data to third-party service providers (e.g., cloud hosting, security verifiers) necessary for our operations, or when required by law.',
            ),
            _buildSection(
              context,
              '4. Security Principle',
              'We implement industry-standard encryption (AES-256) and security protocols to prevent unauthorized access, alteration, or disclosure of your personal data.',
            ),
            _buildSection(
              context,
              '5. Retention Principle',
              'We retain your personal data only for as long as necessary to fulfill the purposes of fraud protection or comply with legal, accounting, or reporting requirements.',
            ),
            _buildSection(
              context,
              '6. Data Integrity Principle',
              'We strive to maintain accurate and up-to-date data. You are encouraged to update your information through the Profile section to ensure its accuracy.',
            ),
            _buildSection(
              context,
              '7. Access Principle',
              'Under PDPA 2010, you have the right to access and correct your personal data. You can manage this through the "Privacy Settings" in your Account tab.',
            ),
            _buildSection(
              context,
              '8. Contact our DPO',
              'If you have questions regarding your data or wish to exercise your rights, contact our Data Protection Officer at:\n\nEmail: dpo@fraudshield.com\nAddress: Kuala Lumpur, Malaysia',
            ),
            _buildSection(
              context,
              '9. Specific Data Collection',
              'FraudShield requires access to sensitive information including Phone State and Call Logs to proactively detect scam calls and protect you from financial fraud. This data is processed locally and in real-time against our threat intelligence database to provide immediate warnings.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

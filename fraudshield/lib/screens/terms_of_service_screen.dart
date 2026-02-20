import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Terms of Service',
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Effective Date: February 20, 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing or using the FraudShield application, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              context,
              '2. Compliance with PDPA 2010',
              'We process your personal data in accordance with the Personal Data Protection Act 2010 (PDPA) of Malaysia. By using our services, you consent to the processing of your personal data as described in our Privacy Policy. We are committed to protecting your privacy and ensuring the security of your personal information.',
            ),
            _buildSection(
              context,
              '3. User Responsibilities',
              'You are responsible for your use of the application and for any content you post. You agree not to:\n• Submit false or misleading scam reports.\n• Harass, abuse, or harm another person.\n• Violate any applicable laws or regulations.\n• Attempt to interfere with the proper functioning of the application.',
            ),
             _buildSection(
              context,
              '4. Intellectual Property',
              'All content, features, and functionality of the application, including but not limited to text, graphics, logos, and software, are the exclusive property of FraudShield and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            _buildSection(
              context,
              '5. Limitation of Liability',
              'To the fullest extent permitted by law, FraudShield shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the service.',
            ),
             _buildSection(
              context,
              '6. Governing Law',
              'These Terms shall be governed and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions.',
            ),
             _buildSection(
              context,
              '7. Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. We will provide notice of any significant changes. Your continued use of the service following the posting of any changes constitutes acceptance of those changes.',
            ),
            _buildSection(
              context,
              '8. Contact Us',
              'If you have any questions about these Terms, please contact us at: legal@fraudshield.com',
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
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

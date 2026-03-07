import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Terms of Service',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Effective Date: February 20, 2026',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using the FraudShield application, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              '2. Compliance with PDPA 2010',
              'We process your personal data in accordance with the Personal Data Protection Act 2010 (PDPA) of Malaysia. By using our services, you provide explicit consent to the processing of your personal data.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'You are responsible for your use of the application and for any content you post. You agree not to:\n• Submit false or misleading scam reports.\n• Harass, abuse, or harm another person.\n• Violate any applicable laws.',
            ),
            _buildSection(
              '4. Intellectual Property',
              'All content, features, and functionality of the application are the exclusive property of FraudShield and are protected by international copyright and trademark laws.',
            ),
            _buildSection(
              '5. Limitation of Liability',
              'To the fullest extent permitted by law, FraudShield shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.',
            ),
            _buildSection(
              '6. Governing Law',
              'These Terms shall be governed and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions.',
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

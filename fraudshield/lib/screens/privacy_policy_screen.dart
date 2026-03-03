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
<<<<<<< HEAD
             Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
=======
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
>>>>>>> dev-ui2
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: February 20, 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
<<<<<<< HEAD
                color: Colors.white.withOpacity(0.6),
              ),
=======
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
>>>>>>> dev-ui2
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
<<<<<<< HEAD
              '1. Introduction',
              'Welcome to FraudShield. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our website (regardless of where you visit it from) or use our application and tell you about your privacy rights and how the law protects you.',
            ),
             _buildSection(
              context,
              '2. Data We Collect',
              'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together follows:\n\n• Identity Data allows us to identify you broadly.\n• Contact Data helps us contact you.\n• Technical Data includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location, browser plug-in types and versions, operating system and platform and other technology on the devices you use to access this website.',
            ),
            _buildSection(
              context,
              '3. How We Use Your Data',
              'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• Where we need to perform the contract we are about to enter into or have entered into with you.\n• Where it is necessary for our legitimate interests (or those of a third party) and your interests and fundamental rights do not override those interests.\n• Where we need to comply with a legal or regulatory obligation.',
            ),
             _buildSection(
              context,
              '4. Data Security',
              'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
            ),
             _buildSection(
              context,
              '5. Contact Us',
              'If you have any questions about this privacy policy or our privacy practices, please contact us at: support@fraudshield.com',
=======
              '1. General Principle',
              'We obtain your explicit consent before collecting and processing your personal data. By registering an account, you consent to the processing of your data as described in this policy.',
            ),
            _buildSection(
              context,
              '2. Notice and Choice Principle',
              'We collect data to provide fraud protection services, improve security algorithms, and communicate alerts. You can choose not to provide certain data, though this may limit functionality.',
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
>>>>>>> dev-ui2
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
<<<<<<< HEAD
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
=======
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
>>>>>>> dev-ui2
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
<<<<<<< HEAD
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
=======
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
>>>>>>> dev-ui2
          ),
        ],
      ),
    );
  }
}

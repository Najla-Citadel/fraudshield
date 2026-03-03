import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/settings_group.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _marketingConsent = true; // Placeholder for actual user preference

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.accountPrivacySettings,
      backgroundColor: AppColors.deepNavy,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.privacyControlDesc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: l10n.privacyDataManagement,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: l10n.privacyRequestDataExport,
                  subtitle: 'Receive a copy of your personal data via email',
                  onTap: () => _showRequestConfirmation(
                      context, l10n.privacyRequestDataExport),
                ),
                SettingsTile(
                  icon: Icons.edit_note_outlined,
                  title: l10n.privacyUpdateInfo,
                  subtitle: l10n.navProfile,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: l10n.privacyWithdrawConsent,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.notifications_none_outlined,
                  title: l10n.privacyConsentMarketing,
                  subtitle: l10n.privacyWithdrawDesc,
                  onTap: () {}, // Handled by Switch but onTap is required
                  trailing: Switch(
                    value: _marketingConsent,
                    onChanged: (val) {
                      setState(() => _marketingConsent = val);
                      // In a real app, call a service to update this
                    },
                    activeColor: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Legal & Contact',
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.contact_support_outlined,
                  title: l10n.privacyDpoContact,
                  subtitle: 'Contact our Data Protection Officer',
                  onTap: () => _showDpoInfo(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestConfirmation(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        title: Text(action, style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Your request has been received. Our support team will process this and contact you at your registered email address within 21 days as per PDPA guidelines.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showDpoInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Protection Officer',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _infoRow(Icons.email_outlined, 'dpo@fraudshield.com'),
            const SizedBox(height: 16),
            _infoRow(Icons.location_on_outlined,
                'FraudShield HQ, Kuala Lumpur, Malaysia'),
            const SizedBox(height: 32),
            const Text(
              'Business Hours: 9:00 AM - 6:00 PM (Mon-Fri)',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

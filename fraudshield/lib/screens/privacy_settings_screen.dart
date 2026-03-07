import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_button.dart';
import '../widgets/settings_group.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _marketingConsent = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      title: l10n.accountPrivacySettings,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                l10n.privacyControlDesc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
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
                  icon: LucideIcons.download,
                  title: l10n.privacyRequestDataExport,
                  subtitle: 'Receive a copy of your personal data via email',
                  onTap: () => _showRequestConfirmation(
                      context, l10n.privacyRequestDataExport),
                ),
                SettingsTile(
                  icon: LucideIcons.fileText,
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
                  icon: LucideIcons.bell,
                  title: l10n.privacyConsentMarketing,
                  subtitle: l10n.privacyWithdrawDesc,
                  onTap: () {},
                  trailing: Switch(
                    value: _marketingConsent,
                    onChanged: (val) {
                      setState(() => _marketingConsent = val);
                    },
                    activeColor: DesignTokens.colors.accentGreen,
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Legal & Contact',
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: LucideIcons.helpCircle,
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
        backgroundColor: DesignTokens.colors.backgroundDark,
        title: Text(action, style: const TextStyle(color: Colors.white)),
        content: Text(
          'Your request has been received. Our support team will process this and contact you at your registered email address within 21 days as per PDPA guidelines.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            label: 'OK',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  void _showDpoInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: DesignTokens.colors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
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
            _infoRow(LucideIcons.mail, 'dpo@fraudshield.com'),
            const SizedBox(height: 16),
            _infoRow(LucideIcons.mapPin,
                'FraudShield HQ, Kuala Lumpur, Malaysia'),
            const SizedBox(height: 32),
            Text(
              'Business Hours: 9:00 AM - 6:00 PM (Mon-Fri)',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
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
        Icon(icon, color: DesignTokens.colors.accentGreen, size: 20),
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

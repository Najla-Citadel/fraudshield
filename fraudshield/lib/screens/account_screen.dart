import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../constants/colors.dart';
import '../constants/app_theme.dart';
import 'login_screen.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/settings_group.dart';
import 'subscription_screen.dart' as crate;
import 'status_details_screen.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'profile_screen.dart';
import 'alert_preferences_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ================= STATE =================
  bool _loading = true;
  bool _hasError = false;
  String _avatarSeed = 'Felix';

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ================= DATA =================
  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    if (profile == null) {
      // Clear flag to avoid infinite loops if it fails persistently
      await authProvider.refreshProfile().catchError((_) => null);
    }

    if (!mounted) return;

    final updatedProfile = authProvider.userProfile;
    _avatarSeed = updatedProfile?.profile?.avatar ?? 'Felix';

    setState(() {
      _loading = false;
      _hasError = false;
    });
  }

  Future<void> _saveAvatar(String seed) async {
    setState(() => _avatarSeed = seed);

    try {
      await ApiService.instance.updateProfile(avatar: seed);
      await context.read<AuthProvider>().refreshProfile();
    } catch (e) {
      log('Error saving avatar: $e');
      _toast('Failed to update avatar');
    }
  }

  // ================= NAVIGATION =================
  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPicker(
        selected: _avatarSeed,
        onSelect: (seed) async {
          Navigator.pop(context);
          await _saveAvatar(seed);
        },
      ),
    );
  }

  void _openPlaceholder(String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('This feature will be available soon.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: ErrorState(onRetry: () {
          setState(() {
            _loading = true;
            _hasError = false;
          });
          _loadProfile();
        }),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Padding(
          padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
          child: Column(
            children: [
              const SkeletonCard(height: 250, margin: EdgeInsets.zero),
              const SizedBox(height: 24),
              const SkeletonCard(height: 150, margin: EdgeInsets.zero),
              const SizedBox(height: 24),
              const SkeletonCard(height: 150, margin: EdgeInsets.zero),
            ],
          ),
        ),
      );
    }

    // Using standard Scaffold for deep navy background
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  AppColors.deepNavy, // Deep navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: AnimationLimiter(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            const SizedBox(height: 20),
                            _premiumProfileHeader(),
                            const SizedBox(height: 16),
                            _statisticsCard(),

                            const SizedBox(height: 24),

                            // Preferences
                            SettingsGroup(
                              title: AppLocalizations.of(context)!
                                  .accountPreferences,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              items: [
                                SettingsTile(
                                  icon: Icons.card_membership,
                                  title: AppLocalizations.of(context)!
                                      .accountSubscriptionPlan,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          context
                                                  .watch<AuthProvider>()
                                                  .isSubscribed
                                              ? AppLocalizations.of(context)!
                                                  .accountPremium
                                              : AppLocalizations.of(context)!
                                                  .accountFree,
                                          style: TextStyle(
                                              color: context
                                                      .watch<AuthProvider>()
                                                      .isSubscribed
                                                  ? Colors.amber
                                                  : Colors.white
                                                      .withValues(alpha: 0.5),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios,
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          size: 14),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const crate
                                              .SubscriptionScreen())),
                                ),
                                SettingsTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: AppLocalizations.of(context)!
                                      .accountNotificationSetting,
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      size: 14),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AlertPreferencesScreen()),
                                  ),
                                ),
                              ],
                            ),

                            // Security
                            SettingsGroup(
                              title: AppLocalizations.of(context)!
                                  .accountSecurityTitle,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              items: [
                                SettingsTile(
                                  icon: Icons.lock_rounded,
                                  title: AppLocalizations.of(context)!
                                      .accountChangePassword,
                                  onTap: _openChangePassword,
                                ),
                              ],
                            ),

                            // Legal
                            SettingsGroup(
                              title: 'Legal',
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              items: [
                                SettingsTile(
                                  icon: Icons.policy_rounded,
                                  title: 'Privacy Policy',
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      size: 14),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/privacy-policy'),
                                ),
                                SettingsTile(
                                  icon: Icons.description_rounded,
                                  title: 'Terms of Service',
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      size: 14),
                                  onTap: () => Navigator.pushNamed(
                                      context, '/terms-of-service'),
                                ),
                                SettingsTile(
                                  icon: Icons.gavel_rounded,
                                  title: 'Manage Consent',
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      size: 14),
                                  onTap: () =>
                                      _openPlaceholder('Manage Consent'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _logoutButton(),
                            // Delete Account Button
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextButton(
                                onPressed: _confirmDeleteAccount,
                                child: Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    color: Colors.red.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Version text with manual white color for safety
                            Text('Version 1.1.0',
                                style: AppTheme.darkTheme.textTheme.labelSmall
                                    ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.white, size: 20),
              onPressed: _showLanguagePicker,
              tooltip: 'Change Language',
            ),
          ),
        ],
      ),
    );
  }

  // =================PASSWORD===================
  void _openChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AdaptiveTextField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  AdaptiveTextField(
                    controller: newCtrl,
                    label: 'New Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  AdaptiveButton(
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            final current = currentCtrl.text.trim();
                            final next = newCtrl.text.trim();

                            setSheetState(() => errorMessage = null);

                            if (current.isEmpty) {
                              setSheetState(() => errorMessage =
                                  'Please enter your current password');
                              return;
                            }
                            if (next.isEmpty) {
                              setSheetState(() =>
                                  errorMessage = 'Please enter a new password');
                              return;
                            }
                            if (next.length < 8) {
                              setSheetState(() => errorMessage =
                                  'New password must be at least 8 characters');
                              return;
                            }
                            if (!next.contains(RegExp(r'[A-Z]'))) {
                              setSheetState(() => errorMessage =
                                  'New password must contain an uppercase letter');
                              return;
                            }
                            if (!next.contains(RegExp(r'[0-9]'))) {
                              setSheetState(() => errorMessage =
                                  'New password must contain a number');
                              return;
                            }

                            setSheetState(() => isLoading = true);

                            ApiService.instance
                                .changePassword(current, next)
                                .then((_) {
                              if (mounted) {
                                Navigator.pop(sheetCtx);
                                _toast('Password updated successfully');
                              }
                            }).catchError((e) {
                              if (mounted) {
                                setSheetState(() {
                                  isLoading = false;
                                  errorMessage = e.toString().contains('400')
                                      ? 'Incorrect current password'
                                      : 'Failed to update password';
                                });
                              }
                              return <String, dynamic>{};
                            });
                          },
                    text: 'Update Password',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final localeProvider = context.watch<LocaleProvider>();
        final currentLocale = localeProvider.locale?.languageCode ?? 'en';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildLanguageItem('English', 'en', currentLocale == 'en', () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              }),
              _buildLanguageItem('Bahasa Malaysia', 'ms', currentLocale == 'ms',
                  () {
                localeProvider.setLocale(const Locale('ms'));
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
      String name, String code, bool isSelected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Text(code == 'en' ? '🇺🇸' : '🇲🇾',
          style: const TextStyle(fontSize: 24)),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.accentGreen)
          : null,
    );
  }

  // ================= COMPONENTS =================

  Widget _premiumProfileHeader() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          GestureDetector(
            onTap: _openAvatarPicker,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1E293B),
                    backgroundImage: NetworkImage(
                      'https://api.dicebear.com/7.x/avataaars/png?seed=$_avatarSeed',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Name and View Profile
          Column(
            children: [
              Text(
                user?.fullName ?? 'Alexander Wright',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statisticsCard() {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.user?.profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tier Badge
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StatusDetailsScreen()),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_rounded,
                            color: Colors.black, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          _calculateTierName(profile?.totalPoints ?? 0),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Benefits and Plan Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plan Indicator
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const crate.SubscriptionScreen()),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          context.watch<AuthProvider>().isSubscribed
                              ? Icons.auto_awesome
                              : Icons.person_outline,
                          color: context.watch<AuthProvider>().isSubscribed
                              ? Colors.amber
                              : Colors.white.withValues(alpha: 0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.watch<AuthProvider>().isSubscribed
                              ? 'Premium Protector'
                              : 'Free Plan',
                          style: TextStyle(
                            color: context.watch<AuthProvider>().isSubscribed
                                ? Colors.amber
                                : Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // View Benefits Link
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StatusDetailsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Benefits',
                        style: TextStyle(
                          color: AppColors.accentGreen.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: AppColors.accentGreen.withValues(alpha: 0.8),
                          size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Account?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone. Your profile and personal data will be permanently removed. Your reports will remain anonymized.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executeAccountDeletion();
    }
  }

  Future<void> _executeAccountDeletion() async {
    setState(() => _loading = true);
    try {
      await ApiService.instance.deleteAccount();
      // Logout and redirect
      if (!mounted) return;
      await context.read<AuthProvider>().signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      _toast('Account deleted successfully');
    } catch (e) {
      log('Error deleting account: $e');
      if (mounted) setState(() => _loading = false);
      _toast('Failed to delete account: $e');
    }
  }

  String _calculateTierName(int totalPoints) {
    if (totalPoints >= 10000) return 'DIAMOND PROTECTOR';
    if (totalPoints >= 5000) return 'GOLD PROTECTOR';
    if (totalPoints >= 1000) return 'SILVER PROTECTOR';
    return 'BRONZE PROTECTOR';
  }

  // Removed _getBadgeEmoji as it is unused
}

// ================= AVATAR PICKER =================
class _AvatarPicker extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const _AvatarPicker({required this.selected, required this.onSelect});

  static const _seeds = [
    'Felix',
    'Aneka',
    'Caleb',
    'Jocelyn',
    'Max',
    'Luna',
    'Kellan',
    'Najla'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _seeds.map((seed) {
          final isSelected = selected == seed;
          return GestureDetector(
            onTap: () => onSelect(seed),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 3)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=$seed',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

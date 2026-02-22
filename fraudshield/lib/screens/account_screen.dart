import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/colors.dart';
import '../constants/app_theme.dart';
import 'login_screen.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/settings_group.dart';
import 'subscription_screen.dart' as crate; // Alias to avoid conflict if any, though likely safe
import 'badges_screen.dart';
import 'status_details_screen.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ================= CONTROLLERS =================
  final TextEditingController _nameController = TextEditingController();

  // ================= STATE =================
  bool _loading = true;
  bool _savingName = false;
  bool _editingName = false;

  String _email = '';
  String _avatarSeed = 'Felix';

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ================= DATA =================
  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    if (profile == null) {
      await authProvider.refreshProfile();
    }

    if (!mounted) return;

    final updatedProfile = authProvider.userProfile;
    _nameController.text = updatedProfile?.fullName ?? '';
    _avatarSeed = updatedProfile?.profile?.avatar ?? 'Felix';
    _email = authProvider.user?.email ?? '';

    setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);

    try {
      await ApiService.instance.updateProfile(
        fullName: _nameController.text.trim(),
      );
      
      // Refresh local state
      await context.read<AuthProvider>().refreshProfile();

      if (!mounted) return;

      setState(() {
        _savingName = false;
        _editingName = false;
      });

      _toast('Name updated');
    } catch (e) {
      log('Error saving name: $e');
      if (mounted) setState(() => _savingName = false);
      _toast('Failed to update name');
    }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    // Using standard Scaffold for deep navy background
    return AdaptiveScaffold(
      title: 'My Account',
      backgroundColor: AppColors.deepNavy,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _premiumProfileHeader(),
            const SizedBox(height: 16),
            _statisticsCard(),
            
            const SizedBox(height: 24),

            // Preferences
            SettingsGroup(
              title: 'Preferences',
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.card_membership,
                  title: 'Subscription Plan',
                  trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       context.watch<AuthProvider>().isSubscribed ? 'Premium' : 'Free', 
                       style: TextStyle(
                         color: context.watch<AuthProvider>().isSubscribed ? Colors.amber : Colors.white.withOpacity(0.5), 
                         fontSize: 13,
                         fontWeight: FontWeight.bold
                       )
                     ),
                     const SizedBox(width: 8),
                     Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
                   ],
                 ),
                  onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const crate.SubscriptionScreen())
                  ),
                ),
                SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () => _openPlaceholder('Notification Settings'),
                ),
                SettingsTile(
                  icon: Icons.language, 
                  title: 'Language',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
                    ],
                  ),
                  onTap: () => _openPlaceholder('Language'),
                ),
                SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: theme.brightness == Brightness.dark,
                    onChanged: (val) => context.read<ThemeProvider>().toggle(val),
                    activeColor: AppColors.accentGreen,
                  ),
                  onTap: () {}, // Handled by switch
                ),
              ],
            ),

            // Security
            SettingsGroup(
              title: 'Security',
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  onTap: _openChangePassword,
                ),
                SettingsTile(
                  icon: Icons.security, 
                  title: 'Two-Factor Authentication',
                  onTap: () => _openPlaceholder('Two-Factor Authentication'),
                ),
                SettingsTile(
                  icon: Icons.devices_rounded,
                  title: 'Device History',
                  onTap: () => _openPlaceholder('Device History'),
                ),
              ],
            ),

            // Legal
             SettingsGroup(
              title: 'Legal',
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              items: [
                SettingsTile(
                  icon: Icons.policy_rounded,
                  title: 'Privacy Policy',
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
                  onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                ),
                 SettingsTile(
                  icon: Icons.description_rounded,
                  title: 'Terms of Service',
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
                  onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
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
                    color: Colors.red.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Version text with manual white color for safety
            Text('Version 1.0.0',
                style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  // =================THEME========================
  void _openThemeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Builder(
          builder: (context) {
            final theme = context.watch<ThemeProvider>();

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: theme.isDark,
                    onChanged: (value) => theme.toggle(value),
                    title: const Text('Dark Mode'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                24, 24, 24,
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
                    onPressed: isLoading ? null : () {
                      final current = currentCtrl.text.trim();
                      final next = newCtrl.text.trim();

                      setSheetState(() => errorMessage = null);

                      if (current.isEmpty) { setSheetState(() => errorMessage = 'Please enter your current password'); return; }
                      if (next.isEmpty) { setSheetState(() => errorMessage = 'Please enter a new password'); return; }
                      if (next.length < 8) { setSheetState(() => errorMessage = 'New password must be at least 8 characters'); return; }
                      if (!next.contains(RegExp(r'[A-Z]'))) { setSheetState(() => errorMessage = 'New password must contain an uppercase letter'); return; }
                      if (!next.contains(RegExp(r'[0-9]'))) { setSheetState(() => errorMessage = 'New password must contain a number'); return; }

                      setSheetState(() => isLoading = true);
                      
                      ApiService.instance.changePassword(current, next).then((_) {
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

  // ================= COMPONENTS =================

  Widget _premiumProfileHeader() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final profile = user?.profile;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Avatar
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user?.fullName ?? 'Alexander Wright',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Tier Badge
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BadgesScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.black, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    context.watch<AuthProvider>().isSubscribed ? 'GOLD PROTECTOR' : 'SILVER PROTECTOR',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // View Status Benefits
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatusDetailsScreen()),
              );
            },
            child: const Text(
              'View Status Benefits ↗',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsCard() {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.user?.profile;
    final points = profile?.points ?? 1250; // Use real points from profile

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PROTECTION POINTS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$points',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' PTS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGreen.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.layers_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RANK',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Top 5%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCAMS BLOCKED',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '142',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _editName() {
    return Column(
      children: [
        AdaptiveTextField(
          controller: _nameController,
          label: 'Full Name',
        ),
        const SizedBox(height: 12),
        AdaptiveButton(
          onPressed: _savingName ? null : _saveName,
          text: 'Save Changes',
          isLoading: _savingName,
        ),
      ],
    );
  }



  Widget _logoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AdaptiveButton(
        onPressed: _logout,
        text: 'Log Out',
        isDestructive: true,
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
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

  String _getBadgeEmoji(String key) {
    switch (key) {
      case 'first_report': return '🎯';
      case 'community_guardian': return '🛡️';
      case 'senior_sentinel': return '🥇';
      case 'first_verify': return '🔍';
      case 'elite_verifier': return '⚖️';
      case 'elite_sentinel': return '💎';
      case 'streak_master': return '🔥';
      default: return '🏅';
    }
  }

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
                border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 3) : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=$seed',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator(strokeWidth: 2));
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

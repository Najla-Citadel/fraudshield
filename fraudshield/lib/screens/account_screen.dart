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
            _editingName 
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _editName(),
                )
              : _compactProfileCard(),
            
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
                  onTap: () => _openPlaceholder('Terms of Service'),
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
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                onPressed: () async {
                  try {
                    await ApiService.instance.changePassword(newCtrl.text.trim());
                    if (!mounted) return;
                    Navigator.pop(context);
                    _toast('Password updated successfully');
                  } catch (e) {
                    _toast('Failed to update password: $e');
                  }
                },
                text: 'Update Password',
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= COMPONENTS =================

  Widget _compactProfileCard() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    'https://api.dicebear.com/7.x/avataaars/png?seed=$_avatarSeed',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 70, height: 70,
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 70, height: 70,
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.person, size: 30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openAvatarPicker,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _editingName = !_editingName),
              icon: Icon(
                _editingName ? Icons.check : Icons.edit,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
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

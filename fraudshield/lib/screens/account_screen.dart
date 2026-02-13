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
            _profileCard(),
            _section('Preferences'),
            // Subscription Management for active subscribers (since they lose the main nav tab)
            if (context.watch<AuthProvider>().isSubscribed)
              _setting(
                Icons.card_membership, 
                'Manage Subscription', 
                () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const crate.SubscriptionScreen())
                )
              ),
            _setting(Icons.notifications, 'Notification Settings',
                () => _openPlaceholder('Notification Settings')),
            _setting(
                Icons.language, 'Language', () => _openPlaceholder('Language')),
            _setting(Icons.brightness_6, 'Theme', _openThemeSheet),
            _section('Security'),
            _setting(
                Icons.lock_outline, 'Change Password', _openChangePassword),
            _setting(Icons.shield_outlined, 'Two-Factor Authentication',
                () => _openPlaceholder('Two-Factor Authentication')),
            _setting(Icons.devices, 'Device History',
                () => _openPlaceholder('Device History')),
            const SizedBox(height: 20),
            _logoutButton(),
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

  Widget _profileCard() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Match Home Screen Widget Background
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    'https://api.dicebear.com/7.x/avataaars/png?seed=$_avatarSeed',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 120, height: 120,
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 120, height: 120,
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.person, size: 60),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openAvatarPicker,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentGreen,
                      child:
                          Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _editingName ? _editName() : _displayName(),
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

  Widget _displayName() {
    // Force white text since we are on a dark slate card regardless of theme
    return Column(
      children: [
        Text(
          _nameController.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() => _editingName = true),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'EDIT PROFILE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
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

  Widget _section(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: SizedBox(
        width: double.infinity,
        child: Text(title.toUpperCase(),
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            )),
      ),
    );
  }

  Widget _setting(IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: _AccountItem(
        icon: icon,
        title: title,
        onTap: onTap,
      ),
    );
  }
}

class _AccountItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccountItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
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

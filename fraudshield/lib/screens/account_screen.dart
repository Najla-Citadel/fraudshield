import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/colors.dart';
import 'login_screen.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';

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

    return AdaptiveScaffold(
      title: 'My Account',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _profileCard(),
            _section('Preferences'),
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
            const Text('Version 1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.black26)),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20),
        ],
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
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _openAvatarPicker,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryBlue,
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
    return Column(
      children: [
        Text(_nameController.text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_email,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => setState(() => _editingName = true),
          child: const Text('EDIT PROFILE'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              letterSpacing: 1.5)),
    );
  }

  Widget _setting(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _seeds.map((seed) {
          return GestureDetector(
            onTap: () => onSelect(seed),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://api.dicebear.com/7.x/avataaars/png?seed=$seed',
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

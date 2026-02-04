// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/secondary_button.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  bool _savingName = false;
  bool _editingName = false;
  String _email = '';
  String _avatarSeed = 'Felix';

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

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final row = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;
    _nameController.text = row?['full_name'] ?? '';
    _avatarSeed = row?['avatar_seed'] ?? 'Felix';
    _email = user.email ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _savingName = true);

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'full_name': _nameController.text.trim(),
    });

    if (!mounted) return;
    setState(() {
      _savingName = false;
      _editingName = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated')));
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 HEADER & PROFILE
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                  padding: const EdgeInsets.only(top: 60, left: 24),
                  alignment: Alignment.topLeft,
                  child: Text('My Account', style: AppTypography.h1.copyWith(color: Colors.white)),
                ),
                Positioned(
                  bottom: -60,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=$_avatarSeed'),
                        ),
                        const SizedBox(height: 16),
                        if (_editingName)
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _nameController)),
                              IconButton(icon: const Icon(Icons.check), onPressed: _saveName),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Text(_nameController.text, style: AppTypography.h2),
                              Text(_email, style: AppTypography.bodyS),
                            ],
                          ),
                         
                         if (!_editingName)
                           TextButton(
                             onPressed: () => setState(() => _editingName = true),
                             child: const Text('Edit Profile'),
                           ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // 🔹 SETTINGS LIST
            _sectionHeader('Preferences'),
            _settingTile(Icons.notifications_outlined, 'Notifications', () {}),
            _settingTile(Icons.language, 'Language', () {}),
            
             _sectionHeader('Security'),
            _settingTile(Icons.lock_outline, 'Change Password', () {}),
            _settingTile(Icons.shield_outlined, 'Two-Factor Auth', () {}),
            
            const SizedBox(height: AppSpacing.xl),

            Padding(
              padding: AppSpacing.screenPadding,
              child: SecondaryButton(
                label: 'Log Out',
                icon: Icons.logout,
                onPressed: _logout,
                color: AppColors.error,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: AppTypography.caption),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTypography.bodyM),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textPlaceholder),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

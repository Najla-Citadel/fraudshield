import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_text_field.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_snackbar.dart';
import 'email_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _resetControllers();
  }

  void _resetControllers() {
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(
      text: user?.profile?.metadata?['address']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.user;

      await ApiService.instance.updateProfile(
        fullName: _nameController.text.trim(),
        metadata: {
          ...?currentUser?.profile?.metadata,
          'address': _addressController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        },
      );

      await auth.refreshProfile();

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Profile updated successfully');
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update profile: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestVerification(String email) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.requestVerificationEmail();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to request verification: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return ScreenScaffold(
      title: _isEditing ? 'Edit Profile' : 'View Profile',
      actions: [
        if (!_isLoading)
          IconButton(
            icon: Icon(_isEditing ? LucideIcons.x : LucideIcons.edit3,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isEditing) _resetControllers();
                _isEditing = !_isEditing;
              });
            },
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(user),
              const SizedBox(height: 32),
              const Text(
                'Personal Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _item(
                label: 'Full Name',
                controller: _nameController,
                isEditing: _isEditing,
                icon: LucideIcons.user,
              ),
              const SizedBox(height: 16),
              _item(
                label: 'Email Address',
                value: user?.email ?? 'N/A',
                isEditing: false,
                icon: LucideIcons.mail,
                trailing: user?.isEmailVerified == true
                    ? Icon(LucideIcons.checkCircle2,
                        color: DesignTokens.colors.accentGreen, size: 16)
                    : GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => _requestVerification(user?.email ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Verify Now',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _item(
                label: 'Phone Number',
                controller: _phoneController,
                isEditing: _isEditing,
                icon: LucideIcons.smartphone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _item(
                label: 'Address',
                controller: _addressController,
                isEditing: _isEditing,
                icon: LucideIcons.mapPin,
                maxLines: 3,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 40),
                AppButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  label: 'Save Changes',
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primary,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            backgroundImage: NetworkImage(
              'https://api.dicebear.com/7.x/avataaars/png?seed=${user?.profile?.avatar ?? "Felix"}',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Anonymous',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required String label,
    String? value,
    TextEditingController? controller,
    required bool isEditing,
    required IconData icon,
    Widget? trailing,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    if (isEditing && controller != null) {
      return AdaptiveTextField(
        controller: controller,
        label: label,
        prefixIcon: icon,
        keyboardType: keyboardType,
        maxLines: maxLines,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DesignTokens.radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: DesignTokens.colors.accentGreen.withValues(alpha: 0.7),
              size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? controller?.text ?? 'Not provided',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }
}

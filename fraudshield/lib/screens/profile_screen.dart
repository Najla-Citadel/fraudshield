import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_text_field.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_snackbar.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'email_verification_screen.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _preferredNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _dialCode;
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
    _preferredNameController = TextEditingController(
      text: user?.profile?.metadata?['preferredName']?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: user?.profile?.mobile ?? '');
    _addressController = TextEditingController(
      text: user?.profile?.mailingAddress ?? '',
    );
    _dialCode = user?.profile?.metadata?['dialCode']?.toString() ?? '+60';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _preferredNameController.dispose();
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
        mobile: _phoneController.text.trim(),
        mailingAddress: _addressController.text.trim(),
        metadata: {
          ...?currentUser?.profile?.metadata,
          'preferredName': _preferredNameController.text.trim(),
          'dialCode': _dialCode ?? '+60',
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
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(user),
              SizedBox(height: 32),
              Text(
                'Personal Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _item(
                label: AppLocalizations.of(context)!.profileFullName,
                controller: _nameController,
                isEditing: _isEditing,
                icon: LucideIcons.user,
              ),
              SizedBox(height: 16),
              _item(
                label: AppLocalizations.of(context)!.profilePreferredName,
                controller: _preferredNameController,
                isEditing: _isEditing,
                icon: LucideIcons.userCircle,
                hintText: AppLocalizations.of(context)!.profilePreferredNameHint,
              ),
              SizedBox(height: 16),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacing.sm, vertical: DesignTokens.spacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Text(
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
              SizedBox(height: 16),
              _phoneItem(
                label: AppLocalizations.of(context)!.profilePhoneNumber,
                controller: _phoneController,
                isEditing: _isEditing,
                icon: LucideIcons.smartphone,
              ),
              SizedBox(height: 16),
              _item(
                label: 'Address',
                controller: _addressController,
                isEditing: _isEditing,
                icon: LucideIcons.mapPin,
                maxLines: 3,
              ),
              if (_isEditing) ...[
                SizedBox(height: 40),
                AppButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  label: 'Save Changes',
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primary,
                ),
                SizedBox(height: 16),
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
          SizedBox(height: 16),
          Text(
            (user?.fullName ?? 'Anonymous').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneItem({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required IconData icon,
  }) {
    if (isEditing) {
      return IntlPhoneField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radii.md),
            borderSide: BorderSide(color: DesignTokens.colors.accentGreen.withValues(alpha: 0.5)),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing.md,
            vertical: DesignTokens.spacing.md,
          ),
        ),
        initialCountryCode: 'MY',
        disableLengthCheck: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        dropdownTextStyle: const TextStyle(color: Colors.white),
        pickerDialogStyle: PickerDialogStyle(
          backgroundColor: const Color(0xFF0F172A),
          countryCodeStyle: const TextStyle(color: Colors.white),
          countryNameStyle: const TextStyle(color: Colors.white),
          searchFieldInputDecoration: InputDecoration(
            hintText: 'Search country',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: Icon(LucideIcons.search, color: Colors.white.withValues(alpha: 0.5), size: 18),
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onCountryChanged: (country) {
          setState(() {
            _dialCode = '+${country.dialCode}';
          });
        },
        onChanged: (phone) {
          // Instead of manually setting controller.text in onChanged (which can cause desync),
          // we use it only to check if we should strip a leading zero
          if (phone.number.startsWith('0')) {
            final newNumber = phone.number.substring(1);
            // Using microtask to avoid changing text while the widget is still processing the event
            Future.microtask(() {
              controller.text = newNumber;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: newNumber.length),
              );
            });
          }
        },
      );
    }

    return _item(
      label: label,
      value: '${_dialCode ?? "+60"} ${controller.text}',
      isEditing: false,
      icon: icon,
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
    String? hintText,
  }) {
    if (isEditing && controller != null) {
      return AdaptiveTextField(
        controller: controller,
        label: label,
        prefixIcon: icon,
        keyboardType: keyboardType,
        maxLines: maxLines,
        hintText: hintText,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.md),
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
          SizedBox(width: 16),
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
                SizedBox(height: 4),
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
            SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/adaptive_button.dart';
import '../constants/colors.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'View Profile', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_isEditing) _resetControllers();
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
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
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              
              _item(
                label: 'Email Address',
                value: user?.email ?? 'N/A',
                isEditing: false, // Email is never editable here
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              
              _item(
                label: 'Phone Number',
                controller: _phoneController,
                isEditing: _isEditing,
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              _item(
                label: 'Address',
                controller: _addressController,
                isEditing: _isEditing,
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
              
              if (_isEditing) ...[
                const SizedBox(height: 40),
                AdaptiveButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  text: 'Save Changes',
                  isLoading: _isLoading,
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
            backgroundColor: Colors.white.withOpacity(0.1),
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGreen.withOpacity(0.7), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
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
        ],
      ),
    );
  }
}

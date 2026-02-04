// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/custom_text_field.dart';
import '../widgets/core/primary_button.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _trySignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user ?? Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
         _showSnack('Sign-up success, please check email/login.', isError: false);
      }
    } on AuthException catch (ae) {
      _showSnack(ae.message, isError: true);
    } catch (e) {
      _showSnack('Sign-up failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: AppSpacing.m),
              
              Text('Create Account', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Join the community and stay safe.',
                style: AppTypography.bodyM,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 📧 Email
              CustomTextField(
                label: 'Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: 'john@example.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.l),

              // 🔒 Password
              CustomTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: AppSpacing.l),

              // 🔒 Confirm Password
              CustomTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: true,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
              ),

              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(
                label: 'Sign Up',
                onPressed: _trySignUp,
                isLoading: _loading,
              ),
              
              const SizedBox(height: AppSpacing.l),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: AppTypography.bodyM),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

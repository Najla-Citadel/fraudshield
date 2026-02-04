// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/custom_text_field.dart';
import '../widgets/core/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _trySignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter email and password', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
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
        _showSnack('Sign-in did not return a user.', isError: true);
      }
    } on AuthException catch (ae) {
      _showSnack(ae.message, isError: true);
    } catch (e) {
      _showSnack('Sign-in failed: $e', isError: true);
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
              const SizedBox(height: AppSpacing.xxl),
              
              // 🧭 Title
              Text('Welcome Back', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Secure your digital life with FraudShield.',
                style: AppTypography.bodyM,
              ),
              
              const SizedBox(height: AppSpacing.xxl),

              // 📧 Email Field
              CustomTextField(
                label: 'Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: 'john@example.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.l),

              // 🔒 Password Field
              CustomTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
              ),

              const SizedBox(height: AppSpacing.s),

              // 🔗 Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showSnack('Forgot password flow not implemented'),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 🟦 Log In Button
              PrimaryButton(
                label: 'Log In',
                onPressed: _trySignIn,
                isLoading: _loading,
              ),

              const SizedBox(height: AppSpacing.l),

              // 👤 Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don’t have an account? ", style: AppTypography.bodyM),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
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


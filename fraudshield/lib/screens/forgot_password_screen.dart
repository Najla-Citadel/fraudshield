import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/glass_surface.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCodeSent = false;
  
  String? _emailError;
  String? _otpError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.requestPasswordReset(email);
      setState(() => _isCodeSent = true);
      
      if (!mounted) return;
      if (response.containsKey('dev_otp')) {
        AppSnackBar.showInfo(context, 'DEV: Code is ${response['dev_otp']}');
      } else {
        AppSnackBar.showSuccess(context, 'Reset code sent to your email.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;

    if (otp.length < 6) {
      setState(() => _otpError = 'Enter 6-digit code');
      return;
    }
    if (newPassword.length < 8) {
      setState(() => _passwordError = 'At least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.instance.resetPassword(email, otp, newPassword);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Password updated. Please log in.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    return ScreenScaffold(
      showBackButton: true,
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.key,
                  size: 40,
                  color: DesignTokens.colors.primary,
                ),
              ),
              const SizedBox(height: 32),

              GlassSurface(
                padding: const EdgeInsets.all(32),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isCodeSent ? 'Verify' : 'Reset Password',
                      textAlign: TextAlign.center,
                      style: DesignTypography.h2.copyWith(
                        color: colors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCodeSent
                          ? 'Enter the 6-digit code sent to your email'
                          : 'Enter your email to receive a reset code',
                      textAlign: TextAlign.center,
                      style: DesignTypography.bodySm.copyWith(
                        color: colors.textLight.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (!_isCodeSent) ...[
                      AdaptiveTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => setState(() => _emailError = null),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Send Code',
                        onPressed: _handleRequestCode,
                        isLoading: _isLoading,
                      ),
                    ] else ...[
                      AdaptiveTextField(
                        controller: _otpController,
                        label: 'Verification Code',
                        prefixIcon: LucideIcons.hash,
                        keyboardType: TextInputType.number,
                        errorText: _otpError,
                        onChanged: (_) => setState(() => _otpError = null),
                      ),
                      const SizedBox(height: 16),
                      AdaptiveTextField(
                        controller: _passwordController,
                        label: 'New Password',
                        prefixIcon: LucideIcons.lock,
                        obscureText: true,
                        errorText: _passwordError,
                        onChanged: (_) => setState(() => _passwordError = null),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Reset Password',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isCodeSent = false),
                        child: Text(
                          'Try another email',
                          style: TextStyle(
                            color: DesignTokens.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

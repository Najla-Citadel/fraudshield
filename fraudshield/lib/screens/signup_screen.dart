import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../design_system/tokens/design_tokens.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/glass_surface.dart';
import '../widgets/app_logo.dart';
import '../widgets/turnstile_widget.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _agreedToTerms = false;
  String? _captchaToken;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      AppSnackBar.showError(context, "Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.showError(context, "Passwords do not match.");
      return;
    }

    if (!_agreedToTerms) {
      AppSnackBar.showWarning(context, "You must agree to the Terms and Privacy Policy to continue.");
      return;
    }

    if (_captchaToken == null) {
      AppSnackBar.showWarning(context, "Please complete the security check.");
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await context.read<AuthProvider>().signUp(
            email: email,
            password: password,
            fullName: fullName,
            captchaToken: _captchaToken,
          );

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email)),
        );
      } else {
        if (!mounted) return;
        AppSnackBar.showError(context, "Sign-up failed. Please try again.");
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      AppSnackBar.showError(context, "Error: $message");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      showBackButton: true,
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🛡️ Logo / Icon
              const AppLogo(size: 80),
              const SizedBox(height: 32),

              // 🧭 Title
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the community to stay protected',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 32),

              // 🌫️ Glass Signup Card
              GlassSurface(
                padding: const EdgeInsets.all(32),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 👤 Full Name
                    AdaptiveTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: LucideIcons.user,
                    ),
                    const SizedBox(height: 16),

                    // 📧 Email Field
                    AdaptiveTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // 🔒 Password Field
                    AdaptiveTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: LucideIcons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // 🔒 Confirm Password Field
                    AdaptiveTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      prefixIcon: LucideIcons.shieldCheck,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // 📝 Terms & Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val ?? false),
                            activeColor: DesignTokens.colors.primary,
                            side: const BorderSide(
                                color: Colors.white54, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.4),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                      color: DesignTokens.colors.primary,
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const TermsOfServiceScreen())),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                      color: DesignTokens.colors.primary,
                                      fontWeight: FontWeight.bold),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const PrivacyPolicyScreen())),
                                ),
                                const TextSpan(
                                    text:
                                        ', and consent to data collection as per PDPA 2010.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🛡️ CAPTCHA Security Check
                    TurnstileWidget(
                      onTokenReceived: (token) {
                        setState(() => _captchaToken = token);
                      },
                    ),

                    const SizedBox(height: 16),

                    // 🟦 Sign Up Button
                    AppButton(
                      label: 'Sign Up',
                      isLoading: _loading,
                      onPressed: _signup,
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🔁 Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: DesignTokens.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
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

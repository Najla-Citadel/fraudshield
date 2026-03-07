import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../providers/auth_provider.dart';
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
  
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Please enter your name' : null;
      _emailError = _emailController.text.isEmpty || !_emailController.text.contains('@') 
          ? 'Enter a valid email' : null;
      _passwordError = _passwordController.text.length < 8 
          ? 'Password must be at least 8 characters' : null;
      _confirmError = _confirmPasswordController.text != _passwordController.text 
          ? 'Passwords do not match' : null;
    });

    return _nameError == null && _emailError == null && 
           _passwordError == null && _confirmError == null;
  }

  Future<void> _signup() async {
    if (!_validate()) return;

    if (!_agreedToTerms) {
      AppSnackBar.showWarning(context, "You must agree to the Terms and Privacy Policy.");
      return;
    }

    if (_captchaToken == null) {
      AppSnackBar.showWarning(context, "Please complete the security check.");
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await context.read<AuthProvider>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            captchaToken: _captchaToken,
          );

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: _emailController.text.trim())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
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
              const AppLogo(size: 80),
              const SizedBox(height: 32),
              
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

              GlassSurface(
                padding: const EdgeInsets.all(32),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: LucideIcons.user,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 16),

                    AdaptiveTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: 16),

                    AdaptiveTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: LucideIcons.lock,
                      obscureText: true,
                      errorText: _passwordError,
                      onChanged: (_) => setState(() => _passwordError = null),
                    ),
                    const SizedBox(height: 16),

                    AdaptiveTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      prefixIcon: LucideIcons.shieldCheck,
                      obscureText: true,
                      errorText: _confirmError,
                      onChanged: (_) => setState(() => _confirmError = null),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val ?? false),
                            activeColor: DesignTokens.colors.primary,
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  height: 1.5),
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
                                const TextSpan(text: ', and consent to AI monitoring.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    TurnstileWidget(
                      onTokenReceived: (token) {
                        setState(() => _captchaToken = token);
                      },
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Sign Up',
                      isLoading: _loading,
                      onPressed: _signup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: DesignTokens.colors.primary,
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

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/app_logo.dart';

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

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the Terms and Privacy Policy to continue.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await context.read<AuthProvider>().signUp(
        email: email, 
        password: password, 
        fullName: fullName,
      );

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-up failed. Please try again.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Extract the message if it's an Exception
      final message = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $message"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme for the signup screen to match the Deep Navy aesthetic
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.deepNavy,
        primaryColor: AppColors.primaryBlue,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryBlue,
          surface: AppColors.deepNavy,
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
        extendBodyBehindAppBar: true, 
        body: Stack(
          children: [
            // Background Elements (Matching Login Screen)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A), // Slate 900
                      AppColors.deepNavy, // Base
                      Color(0xFF1E3A8A), // Blue 900
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
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
                          color: Colors.white.withOpacity(0.7),
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
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // 📧 Email Field
                            AdaptiveTextField(
                              controller: _emailController,
                              label: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // 🔒 Password Field
                            AdaptiveTextField(
                              controller: _passwordController,
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),

                            // 🔒 Confirm Password Field
                            AdaptiveTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              prefixIcon: Icons.lock_reset_outlined,
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
                                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                                    activeColor: AppColors.primaryBlue,
                                    side: const BorderSide(color: Colors.white54, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                                        ),
                                        const TextSpan(text: ', and consent to data collection as per PDPA 2010.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // 🟦 Sign Up Button
                            AdaptiveButton(
                              text: 'Sign Up',
                              isLoading: _loading,
                              onPressed: _signup,
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
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
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
            ),
          ],
        ),
      ),
    );
  }
}

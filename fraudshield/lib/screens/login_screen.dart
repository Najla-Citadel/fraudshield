import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/animated_background.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await context.read<AuthProvider>().signIn(
        email: email, 
        password: password,
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
          const SnackBar(content: Text('Invalid credentials. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow background to show through status bar
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🛡️ Logo / Icon (Optional)
                  Icon(
                    Icons.shield_outlined, 
                    size: 64, 
                    color: theme.colorScheme.primary
                  ),
                  const SizedBox(height: 24),
                
                  // 🌫️ Glass Login Card
                  GlassSurface(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🧭 Title
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue to FraudShield',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

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

                        const SizedBox(height: 12),

                        // 🔗 Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Forgot password flow not implemented')),
                              );
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🟦 Log In Button
                        AdaptiveButton(
                          text: 'Log In',
                          isLoading: _loading,
                          onPressed: _trySignIn,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 👆 Biometric Placeholder
                  IconButton(
                    icon: Icon(Icons.fingerprint, size: 48, color: theme.colorScheme.primary),
                    onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Biometric Login coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 👤 Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account? ",
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
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
      ),
    );
  }
}

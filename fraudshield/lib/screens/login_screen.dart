import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/app_logo.dart';
import '../services/api_service.dart';
import 'forgot_password_screen.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initializationFuture;
  bool _initSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      debugPrint('Google Sign-In: Initializing...');
      final serverClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      debugPrint('Google Sign-In: Using serverClientId: $serverClientId');
      await _googleSignIn.initialize(
        serverClientId: serverClientId,
      ).timeout(const Duration(seconds: 10));
      debugPrint('Google Sign-In: Initialization complete.');
      _initSuccess = true;
    } catch (e) {
      debugPrint('Google Sign-In: Initialization ERROR: $e');
      _initSuccess = false;
    }
  }

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

  Future<void> _tryGoogleSignIn() async {
    debugPrint('Google Sign-In: Starting flow...');
    setState(() => _loading = true);

    try {
      // 0. Ensure initialized
      if (_initializationFuture != null) {
        debugPrint('Google Sign-In: Waiting for initialization...');
        await _initializationFuture!.timeout(const Duration(seconds: 10));
      }

      if (!_initSuccess) {
        throw Exception('Google Sign-In failed to initialize. Check your configuration.');
      }

      // 1. Trigger Google account picker
      debugPrint('Google Sign-In: Calling authenticate()...');
      final GoogleSignInAccount? account = await _googleSignIn.authenticate()
          .timeout(const Duration(seconds: 45));
      
      if (account == null) {
        debugPrint('Google Sign-In: User canceled or picker returned null.');
        return;
      }
      debugPrint('Google Sign-In: Authentication successful for ${account.email}');
      
      // 2. Get the auth tokens (must be awaited — async in google_sign_in v6+)
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      debugPrint('Google Sign-In: ID Token retrieved: ${idToken != null}');

      if (idToken == null) {
        throw Exception('Failed to get Google ID Token');
      }

      // 3. Authenticate with backend
      if (!mounted) return;
      debugPrint('Google Sign-In: Calling backend /auth/google...');
      final success = await context.read<AuthProvider>().signInWithGoogle(idToken);
      debugPrint('Google Sign-In: Backend response success: $success');
      
      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      debugPrint('Google Sign-In: Flow finished.');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme for the login screen to match the Deep Navy aesthetic
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
            // Background Elements (Optional: subtle gradient or orbs if desired, 
            // but Home Screen is mostly solid. We'll use a subtle gradient to give it depth)
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
                    
                      // 🌫️ Glass Login Card
                      GlassSurface(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 🧭 Title
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue to FraudShield',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue, 
                                    fontWeight: FontWeight.w600
                                  ),
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

                            const SizedBox(height: 24),

                            // 🔘 OR Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ⚪ Google Sign In Button
                            InkWell(
                              onTap: _loading ? null : _tryGoogleSignIn,
                              borderRadius: BorderRadius.circular(16),
                              child: GlassSurface(
                                opacity: 0.1,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                borderRadius: 16,
                                borderColor: Colors.white.withOpacity(0.2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                                      height: 20,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.login, 
                                        size: 20, 
                                        color: Colors.white
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 👆 Biometric Placeholder
                      IconButton(
                        icon: const Icon(Icons.fingerprint, size: 48, color: AppColors.primaryBlue),
                        onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometric Login coming soon!')),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 👤 Sign Up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don’t have an account? ",
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/privacy-policy');
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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

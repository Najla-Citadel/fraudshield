import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/glass_surface.dart';
import '../widgets/app_logo.dart';
import 'forgot_password_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../design_system/components/app_divider.dart';

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
      const serverClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      debugPrint('Google Sign-In: Using serverClientId: $serverClientId');
      await _googleSignIn
          .initialize(
            serverClientId: serverClientId,
          )
          .timeout(const Duration(seconds: 10));
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
      AppSnackBar.showError(context, 'Please enter email and password');
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
        AppSnackBar.showError(context, 'Invalid credentials. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      AppSnackBar.showError(context, "Error: $message");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tryGoogleSignIn() async {
    debugPrint('Google Sign-In: Starting flow...');
    setState(() => _loading = true);

    try {
      if (_initializationFuture != null) {
        debugPrint('Google Sign-In: Waiting for initialization...');
        await _initializationFuture!.timeout(const Duration(seconds: 10));
      }

      if (!_initSuccess) {
        throw Exception(
            'Google Sign-In failed to initialize. Check your configuration.');
      }

      debugPrint('Google Sign-In: Calling authenticate()...');
      final account = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 45));

      debugPrint(
          'Google Sign-In: Authentication successful for ${account.email}');

      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      debugPrint('Google Sign-In: ID Token retrieved: ${idToken != null}');

      if (idToken == null) {
        throw Exception('Failed to get Google ID Token');
      }

      if (!mounted) return;
      debugPrint('Google Sign-In: Calling backend /auth/google...');
      final success =
          await context.read<AuthProvider>().signInWithGoogle(idToken);
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
      AppSnackBar.showError(context, "Google Sign-In failed: ${e.toString()}");
    } finally {
      debugPrint('Google Sign-In: Flow finished.');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignTokens.colors;
    return ScreenScaffold(
      showBackButton: false,
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 80),
              const SizedBox(height: 32),
              AnimationConfiguration.synchronized(
                duration: const Duration(milliseconds: 800),
                child: FadeInAnimation(
                  curve: Curves.easeOutCubic,
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: GlassSurface(
                      padding: const EdgeInsets.all(32),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.loginWelcomeBack,
                            textAlign: TextAlign.center,
                            style: DesignTypography.h2.copyWith(
                              color: colors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.loginSignInDesc,
                            textAlign: TextAlign.center,
                            style: DesignTypography.bodyMd.copyWith(
                              color: colors.textLight.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 32),
                          AdaptiveTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: LucideIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          AdaptiveTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefixIcon: LucideIcons.lock,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.loginForgotPassword,
                                style: TextStyle(
                                    color: DesignTokens.colors.accentGreen,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Log In',
                            isLoading: _loading,
                            onPressed: _trySignIn,
                            variant: AppButtonVariant.primary,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: const AppDivider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                  AppLocalizations.of(context)!.loginOr,
                                  style: TextStyle(
                                    color: colors.textLight.withValues(alpha: 0.4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: colors.textLight.withValues(alpha: 0.2))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Sign in with Google',
                            onPressed: _loading ? null : _tryGoogleSignIn,
                            variant: AppButtonVariant.outline,
                            icon: LucideIcons.logIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t have an account? ",
                    style: TextStyle(color: colors.textLight.withValues(alpha: 0.7)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.loginSignUp,
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

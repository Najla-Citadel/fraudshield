import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/glass_surface.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyEmail() async {
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.instance.verifyEmail(widget.email, otp);
      
      if (!mounted) return;
      
      AppSnackBar.showSuccess(context, 'Email verified successfully!');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().resendVerificationEmail();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Verification code resent successfully!');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Verify Email',
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacing.xl),
                  decoration: BoxDecoration(
                    color: DesignTokens.colors.backgroundDark,
                    shape: BoxShape.circle,
                    boxShadow: DesignTokens.shadows.md,
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    LucideIcons.mailCheck,
                    size: 48,
                    color: DesignTokens.colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              GlassSurface(
                padding: EdgeInsets.all(DesignTokens.spacing.xxxl),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the 6-digit code we sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(DesignTokens.spacing.md),
                        margin: EdgeInsets.only(bottom: DesignTokens.spacing.xxl),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    AdaptiveTextField(
                      controller: _otpController,
                      label: '6-Digit Code',
                      prefixIcon: LucideIcons.hash,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    
                    // 🛡️ Debug Mode OTP Hint
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.devOtp != null && (ApiService.baseUrl.contains('10.0.2.2') || ApiService.baseUrl.contains('localhost'))) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: DesignTokens.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: DesignTokens.colors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.terminal, size: 14, color: DesignTokens.colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Development OTP: ${auth.devOtp}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: DesignTokens.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Verify Email',
                      onPressed: _handleVerifyEmail,
                      isLoading: _isLoading,
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _handleResendCode,
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: DesignTokens.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

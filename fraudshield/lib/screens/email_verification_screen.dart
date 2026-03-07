import 'package:flutter/material.dart';
import '../design_system/tokens/design_tokens.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_text_field.dart';
import '../widgets/glass_surface.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import '../design_system/components/app_snackbar.dart';

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
      
      // Navigate to Home Screen on success
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: DesignTokens.colors.backgroundDark,
        primaryColor: DesignTokens.colors.primary,
        colorScheme: ColorScheme.dark(
          primary: DesignTokens.colors.primary,
          surface: DesignTokens.colors.backgroundDark,
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: DesignTokens.colors.backgroundDark,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            // Background Elements matching LoginScreen
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A), // Slate 900
                      DesignTokens.colors.backgroundDark, // Base
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
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl, vertical: DesignTokens.spacing.lg),
                  child: Column(
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
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 48,
                            color: DesignTokens.colors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      GlassSurface(
                        padding: EdgeInsets.all(DesignTokens.spacing.xxxl),
                        borderRadius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Verify Your Email',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            Text(
                              'Enter the 6-digit code we sent to\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 32),

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
                                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            AdaptiveTextField(
                              controller: _otpController,
                              label: '6-Digit Code',
                              prefixIcon: Icons.numbers,
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 32),
                            AdaptiveButton(
                              text: 'Verify Email',
                              onPressed: _isLoading ? () {} : _handleVerifyEmail,
                              isLoading: _isLoading,
                            ),
                          ],
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

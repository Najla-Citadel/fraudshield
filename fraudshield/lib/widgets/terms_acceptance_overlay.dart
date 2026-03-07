import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/tokens/design_tokens.dart';
import '../providers/auth_provider.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'glass_surface.dart';
import 'adaptive_button.dart';
import '../design_system/components/app_snackbar.dart';

class TermsAcceptanceOverlay extends StatefulWidget {
  const TermsAcceptanceOverlay({super.key});

  @override
  State<TermsAcceptanceOverlay> createState() => _TermsAcceptanceOverlayState();
}

class _TermsAcceptanceOverlayState extends State<TermsAcceptanceOverlay> {
  bool _agreed = false;
  bool _loading = false;

  Future<void> _onAccept() async {
    if (!_agreed) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().acceptTerms('v1.0');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 🌫️ Blur Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

          // 📜 Modal Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
              child: Hero(
                tag: 'terms_acceptance',
                child: GlassSurface(
                  padding: EdgeInsets.all(DesignTokens.spacing.xxxl),
                  borderRadius: 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security_outlined,
                          size: 64, color: DesignTokens.colors.primary),
                      SizedBox(height: 24),
                      Text(
                        'Updates to Privacy & Terms',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'To continue using FraudShield, please review and accept our updated Privacy Policy and Terms of Service. This ensures compliance with PDPA 2010 and security standards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 32),

                      // 📝 Checkbox & Legal Links
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (val) =>
                                setState(() => _agreed = val ?? false),
                            activeColor: DesignTokens.colors.primary,
                            side: BorderSide(
                                color: Colors.white54, width: 2),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: DesignTokens.spacing.md),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: DesignTokens.colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const TermsOfServiceScreen()),
                                            ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: DesignTokens.colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PrivacyPolicyScreen()),
                                            ),
                                    ),
                                    const TextSpan(
                                        text:
                                            ', and consent to data collection as per PDPA 2010.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // 🟦 Accept Button
                      AdaptiveButton(
                        text: 'Accept & Continue',
                        onPressed: _agreed ? _onAccept : null,
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

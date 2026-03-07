import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../providers/auth_provider.dart';
import '../services/version_service.dart';
import '../services/security_service.dart';
import '../design_system/tokens/design_tokens.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    // Logic moved to build/Consumer for reactive navigation
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Initial Loading State
    if (auth.loading) {
      return Scaffold(
        backgroundColor: DesignTokens.colors.backgroundDark,
        body: AppLoadingIndicator.center(),
      );
    }

    // Navigation Check
    // We use a Future.microtask to avoid calling setState (navigator push) during build
    Future.microtask(() async {
      if (!mounted) return;

      // 🛡️ SECURITY CHECK FIRST
      final isSecure = await SecurityService.instance.checkSecurity();
      if (!isSecure && !kDebugMode) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/security-alert');
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

      if (!mounted) return;

      if (!onboardingDone) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Run version check before home/login
        if (mounted) {
          await VersionService.instance.checkVersion(context);
        }

        if (auth.isAuthenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/splash'); // Or login
        }
      }
    });

    // While deciding/navigating, show spinner
    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
      body: AppLoadingIndicator.center(),
    );
  }
}

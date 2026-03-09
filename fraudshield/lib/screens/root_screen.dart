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
  bool _navigationTriggered = false;
  
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    if (_navigationTriggered) return;
    _navigationTriggered = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Initial Loading State handled in build
    if (auth.loading) {
      await Future.delayed(const Duration(milliseconds: 100));
      _navigationTriggered = false; // reset to allow check when loading finished
      _checkNavigation();
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If loading just finished and we haven't navigated yet, trigger it
    if (!auth.loading && !_navigationTriggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkNavigation());
    }

    // Initial Loading State
    if (auth.loading) {
      return Scaffold(
        backgroundColor: DesignTokens.colors.backgroundDark,
        body: AppLoadingIndicator.center(),
      );
    }

    // While deciding/navigating, show spinner
    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
      body: AppLoadingIndicator.center(),
    );
  }
}

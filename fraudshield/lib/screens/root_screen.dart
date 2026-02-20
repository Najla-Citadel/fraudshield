import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/colors.dart';

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

  Future<void> _navigateTo(String route) async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Initial Loading State
    if (auth.loading) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Navigation Check
    // We use a Future.microtask to avoid calling setState (navigator push) during build
    Future.microtask(() async {
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

      if (!mounted) return;

      if (!onboardingDone) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/splash'); // Or login
      }
    });

    // While deciding/navigating, show spinner
    return const Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scam_map_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_service_screen.dart';

class AppRouter {
  static Route generate(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const RootScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/privacy-policy':
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case '/terms-of-service':
        return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/scam-map':
        return MaterialPageRoute(builder: (_) => const ScamMapScreen());
      default:
        return MaterialPageRoute(builder: (_) => const RootScreen());
    }
  }
}

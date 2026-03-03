import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scam_map_screen.dart';

import 'screens/splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/leaderboard_screen.dart';
<<<<<<< HEAD
=======
import 'screens/alert_center_screen.dart';
import 'screens/scam_insight_screen.dart';
import 'screens/privacy_settings_screen.dart';
>>>>>>> dev-ui2

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

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
      case '/leaderboard':
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());
<<<<<<< HEAD
=======
      case '/alert-center':
        return MaterialPageRoute(builder: (_) => const AlertCenterScreen());
      case '/scam-insight':
        return MaterialPageRoute(builder: (_) => const ScamInsightScreen());
      case '/privacy-settings':
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
>>>>>>> dev-ui2
      default:
        return MaterialPageRoute(builder: (_) => const RootScreen());
    }
  }
}

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
import 'screens/alert_center_screen.dart';
import 'screens/scam_scanner_screen.dart';
import 'screens/security_audit_logs_screen.dart';
import 'screens/transaction_journal_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/security_alert_screen.dart';
import 'screens/voice_detection_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/scam_reporting_screen.dart';
import 'screens/fraud_check_result_screen.dart';
import 'screens/features/caller_id_setup_screen.dart';
import 'services/risk_evaluator.dart';
import 'services/scam_scanner_service.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String scamIntelligenceDetail = '/scam-intelligence-detail';
  static const String deviceScan = '/device-scan';

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
      case '/alert-center':
        return MaterialPageRoute(builder: (_) => const AlertCenterScreen());
      case '/device-scan':
        final scanResult = settings.arguments as ScamScannerResult?;
        return MaterialPageRoute(builder: (_) => ScamScannerScreen(initialResult: scanResult));
      case '/security-logs':
        return MaterialPageRoute(builder: (_) => const SecurityAuditLogsScreen());
      case '/privacy-settings':
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      case '/security-alert':
        return MaterialPageRoute(builder: (_) => const SecurityAlertScreen());
      case '/voice-scan':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VoiceDetectionScreen(
            autoStart: args?['autoStart'] ?? false,
          ),
        );
      case '/subscription':
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
      case '/report':
        return MaterialPageRoute(builder: (_) => const ScamReportingScreen());
      case '/transaction-journal':
        return MaterialPageRoute(builder: (_) => const TransactionJournalScreen());
      case '/fraud-check-result':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FraudCheckResultScreen(
            result: args?['result'] as RiskResult,
            searchValue: args?['searchValue'] as String,
          ),
        );
      case '/caller-id-setup':
        return MaterialPageRoute(builder: (_) => const CallerIdSetupScreen());
      default:
        return MaterialPageRoute(builder: (_) => const RootScreen());
    }
  }
}

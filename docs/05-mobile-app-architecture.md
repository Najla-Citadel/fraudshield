# 5. Mobile App Architecture

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield Mobile |
| Version | 1.1.0 (Build 9) |
| Platform | Android (iOS framework in place) |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 5.1 Architecture Pattern

FraudShield uses the **Provider Pattern** (ChangeNotifierProvider) for state management with a **Service-Oriented Architecture** for business logic and API communication.

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Screens  │ │ Widgets  │ │ Design   │ │ Layouts  │       │
│  │ (58 files)│ │ (custom) │ │ System   │ │ Scaffold │       │
│  └────┬─────┘ └────┬─────┘ └──────────┘ └──────────┘       │
│       │             │                                        │
├───────┴─────────────┴────────────────────────────────────────┤
│                       State Management Layer                  │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐     │
│  │ AuthProvider  │ │ThemeProvider │ │ LocaleProvider    │     │
│  │ (user, auth,  │ │ (dark/light) │ │ (en/ms)          │     │
│  │  subscription)│ └──────────────┘ └──────────────────┘     │
│  └──────┬───────┘                                            │
│         │                                                    │
├─────────┴────────────────────────────────────────────────────┤
│                       Service Layer (Singletons)              │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────────────┐      │
│  │ ApiService   │ │SecuritySvc   │ │NotificationSvc   │      │
│  │ (HTTP+JWT)   │ │(integrity)   │ │(FCM+local+overlay)│     │
│  ├─────────────┤ ├──────────────┤ ├──────────────────┤      │
│  │AttestationSvc│ │CallStateSvc  │ │ClipboardMonitor  │      │
│  │(Play Integ.) │ │(Phase 2)     │ │(background scan)  │     │
│  ├─────────────┤ ├──────────────┤ ├──────────────────┤      │
│  │ScamScannerSvc│ │BiometricSvc  │ │ScamSyncSvc       │      │
│  │(device scan)  │ │(fingerprint) │ │(offline DB)       │     │
│  ├─────────────┤ ├──────────────┤ ├──────────────────┤      │
│  │SocketService │ │VersionSvc    │ │NewsSvc            │     │
│  │(WebSocket)   │ │(updates)     │ │(security feed)    │     │
│  └─────────────┘ └──────────────┘ └──────────────────┘      │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                       Data Layer                              │
│  ┌───────────────┐ ┌──────────────┐ ┌──────────────────┐    │
│  │FlutterSecure  │ │ SQLite       │ │ SharedPrefs      │    │
│  │Storage (AES)  │ │ (local DB)   │ │ (settings)       │    │
│  │ - JWT tokens  │ │ - scam cache │ │ - theme, locale  │    │
│  │ - device ID   │ │ - offline    │ │ - onboarding     │    │
│  └───────────────┘ └──────────────┘ └──────────────────┘    │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                       Platform Layer (Native)                 │
│  ┌─────────────────┐ ┌──────────────────┐ ┌───────────┐     │
│  │ForegroundService │ │CallScreeningService│ │OverlaySvc │    │
│  │(call monitoring)  │ │(Android 10+)      │ │(system UI)│    │
│  └─────────────────┘ └──────────────────┘ └───────────┘     │
└───────────────────────────────────────────────────────────────┘
```

---

## 5.2 Module Structure

### Directory Layout
```
fraudshield/lib/
├── main.dart                    # App entry + overlayMain() + callbackDispatcher()
├── app_router.dart              # Centralized route definitions
├── app.dart                     # MaterialApp configuration
│
├── screens/                     # 58 screen files
│   ├── home_screen.dart         # Main dashboard (1922 lines)
│   ├── root_screen.dart         # Entry point navigation
│   ├── scam_reporting_screen.dart # 4-step wizard (1125 lines)
│   ├── scam_scanner_screen.dart # Device audit (533 lines)
│   ├── voice_detection_screen.dart # AI voice analysis
│   ├── login_screen.dart        # Authentication (355 lines)
│   ├── signup_screen.dart       # Registration (284 lines)
│   ├── splash_screen.dart       # Brand animation
│   ├── onboarding_screen.dart   # Tutorial
│   ├── account_screen.dart      # Profile & settings
│   ├── points_screen.dart       # Gamification
│   ├── trending_scams_screen.dart # Community map
│   ├── community_feed_screen.dart # Social feed
│   ├── subscription_screen.dart # Premium plans
│   ├── fraud_check_screen.dart  # ID verification
│   ├── url_link_check_screen.dart # Phishing analysis
│   ├── qr_detection_screen.dart # QR scanner
│   ├── ai_file_scanner_screen.dart # APK/PDF scan
│   ├── message_analysis_screen.dart # SMS detection
│   ├── scam_alerts_screen.dart  # Threat feed
│   ├── security_audit_logs_screen.dart # Threat history
│   ├── transaction_journal_screen.dart # Payment log
│   ├── alert_center_screen.dart # Notifications
│   ├── scam_map_screen.dart     # Geolocation map
│   ├── leaderboard_screen.dart  # Rankings
│   ├── report_details_screen.dart # Single report
│   ├── report_history_screen.dart # User reports
│   ├── privacy_settings_screen.dart # Data controls
│   ├── email_verification_screen.dart # OTP entry
│   ├── forgot_password_screen.dart # Recovery
│   ├── caller_id_setup_screen.dart # Phase 2 setup
│   └── security_alert_screen.dart # Jailbreak warning
│
├── services/                    # 18 service files
│   ├── api_service.dart         # HTTP client (300+ methods)
│   ├── notification_service.dart # FCM + local + overlay
│   ├── security_service.dart    # Integrity checks
│   ├── attestation_service.dart # Play Integrity
│   ├── call_state_service.dart  # Call monitoring
│   ├── scam_scanner_service.dart # Native bridge
│   ├── clipboard_monitor_service.dart # Background scan
│   ├── socket_service.dart      # WebSocket
│   ├── scam_sync_service.dart   # Offline sync
│   ├── biometric_service.dart   # Auth guard
│   ├── version_service.dart     # Update check
│   └── news_service.dart        # Feed fetching
│
├── providers/                   # 3 provider files
│   ├── auth_provider.dart       # User auth state
│   ├── theme_provider.dart      # Theme management
│   └── locale_provider.dart     # Language switching
│
├── models/                      # 4 model files
│   ├── user_model.dart          # User data model
│   ├── badge_model.dart         # Badge definitions
│   ├── news_item.dart           # News articles
│   └── onboarding_item.dart     # Tutorial data
│
├── design_system/               # Design tokens & components
│   ├── tokens/
│   │   ├── design_tokens.dart   # Colors, spacing, radii, shadows
│   │   └── typography.dart      # Font sizes, weights, styles
│   ├── components/
│   │   ├── app_button.dart      # Primary/Secondary/Outline buttons
│   │   ├── app_snackbar.dart    # Notification toasts
│   │   ├── app_divider.dart     # Separators
│   │   ├── app_loading_indicator.dart # Spinners
│   │   ├── app_skeleton.dart    # Loading placeholders
│   │   ├── app_empty_state.dart # Empty state UI
│   │   └── app_back_button.dart # Navigation
│   └── layouts/
│       └── screen_scaffold.dart # Standard screen wrapper
│
├── widgets/                     # Shared widgets
│   ├── glass_surface.dart       # Glassmorphism container
│   ├── adaptive_text_field.dart # Theme-aware input
│   ├── adaptive_button.dart     # Device-specific button
│   ├── floating_nav_bar.dart    # Bottom navigation (5 tabs)
│   ├── security_report_sheet.dart # Bottom sheet
│   ├── security_tips_card.dart  # Educational tips
│   ├── caller_risk_overlay.dart # Phase 2 overlay
│   ├── macau_intervention_overlay.dart # Phase 2
│   ├── post_call_safety_check.dart # Phase 2
│   └── cooldown_banner.dart     # Rate limit UI
│
├── constants/                   # App constants
│   ├── app_theme.dart           # Light/Dark theme definitions
│   ├── colors.dart              # Extended color palette
│   └── news_categories.dart     # Category filter options
│
├── l10n/                        # Localization
│   ├── app_localizations.dart   # Base delegate
│   ├── app_localizations_en.dart # English strings
│   └── app_localizations_ms.dart # Bahasa Malaysia strings
│
└── utils/                       # Utility functions
```

---

## 5.3 Technology Stack

### Core Framework
| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | 3.0+ | Cross-platform UI framework |
| Dart | 3.0+ | Programming language |
| Provider | 6.0.5 | State management |

### Firebase
| Package | Purpose |
|---------|---------|
| firebase_core | Firebase initialization |
| firebase_messaging | FCM push notifications |
| firebase_crashlytics | Error reporting |
| firebase_auth | Google Sign-In backend |

### Security
| Package | Purpose |
|---------|---------|
| http_certificate_pinning | 3.0.1 | SHA-256 certificate pinning |
| flutter_secure_storage | AES-encrypted key-value store |
| flutter_jailbreak_detection | Root/jailbreak detection |
| local_auth | Biometric authentication |

### Networking
| Package | Purpose |
|---------|---------|
| http | HTTP client |
| socket_io_client | Real-time WebSocket |
| workmanager | Background periodic tasks |

### Phone & Call
| Package | Purpose |
|---------|---------|
| phone_state | 3.0.1 | Call state monitoring |
| flutter_foreground_task | Background service |
| flutter_overlay_window | System-wide overlays |

### Media & Input
| Package | Purpose |
|---------|---------|
| mobile_scanner | 7.1.3 | QR code scanning |
| record | 6.0.0 | Audio recording |
| file_picker | File selection |
| image_picker | Photo capture |

### Maps & Location
| Package | Purpose |
|---------|---------|
| google_maps_flutter | Map widget |
| geolocator | GPS location |
| geocoding | Address resolution |

### UI & Animation
| Package | Purpose |
|---------|---------|
| lottie | Lottie animations |
| shimmer | Loading placeholders |
| lucide_icons | Icon library |
| google_fonts | Typography |
| fl_chart | Data visualization |

### Storage
| Package | Purpose |
|---------|---------|
| sqflite | 2.3.0 | Local SQLite database |
| shared_preferences | Simple key-value storage |
| path_provider | File system paths |

### Device
| Package | Purpose |
|---------|---------|
| device_info_plus | Device identification |
| package_info_plus | App version info |

---

## 5.4 Navigation Architecture

### Router Configuration (app_router.dart)
```dart
Routes:
  '/'                    → RootScreen (splash/auth/home decision)
  '/splash'              → SplashScreen
  '/onboarding'          → OnboardingScreen
  '/login'               → LoginScreen
  '/home'                → HomeScreen (main dashboard + TabBar)
  '/subscription'        → SubscriptionScreen
  '/report'              → ScamReportingScreen (4-step wizard)
  '/device-scan'         → ScamScannerScreen
  '/voice-scan'          → VoiceDetectionScreen
  '/security-logs'       → SecurityAuditLogsScreen
  '/security-alert'      → SecurityAlertScreen
  '/privacy-settings'    → PrivacySettingsScreen
  '/caller-id-setup'     → CallerIdSetupScreen (Phase 2)
  '/transaction-journal' → TransactionJournalScreen
  '/alert-center'        → AlertCenterScreen
  '/scam-map'            → ScamMapScreen
  '/leaderboard'         → LeaderboardScreen
  '/terms-of-service'    → TermsOfServiceScreen
  '/privacy-policy'      → PrivacyPolicyScreen
```

### Navigation Pattern
- `AppRouter.navigatorKey` for programmatic navigation
- `RootScreen` handles initial routing based on auth/onboarding state
- `HomeScreen` uses `IndexedStack` for tab navigation (preserves state)
- `FloatingNavBar` with 5 tabs: Home, Trending, Community, Points, Account

---

## 5.5 Entry Points

The app has **three distinct entry points**:

### 1. `main()` — Primary App Entry
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Configure Crashlytics error handlers
  // Initialize Workmanager for background sync
  runApp(FraudShieldApp());
}
```

### 2. `overlayMain()` — Overlay Service Entry
```dart
@pragma("vm:entry-point")
void overlayMain() {
  // Called from native Android when overlay window is triggered
  // Renders caller risk overlay / Macau intervention overlay
  runApp(OverlayApp());
}
```

### 3. `callbackDispatcher()` — Background Task Entry
```dart
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "scamNumberSync") {
      await ScamSyncService.performSync();
    }
    return true;
  });
}
```

---

## 5.6 Data Flow Architecture

```
┌─────────────────────────────────────────────────────┐
│                    USER INTERACTION                   │
│                                                       │
│  Screen → Provider/setState → ApiService → Backend   │
│                                    │                  │
│  Screen ← Provider.notifyListeners ← Response        │
│                                                       │
├─────────────────────────────────────────────────────┤
│                   LOCAL STORAGE                       │
│                                                       │
│  FlutterSecureStorage ←→ JWT tokens, device ID       │
│  SQLite (sqflite)     ←→ Scam number cache (offline) │
│  SharedPreferences    ←→ Theme, locale, onboarding   │
│                                                       │
├─────────────────────────────────────────────────────┤
│                  REAL-TIME CHANNELS                   │
│                                                       │
│  Socket.io       ←→ Live comments, alerts, threats   │
│  FCM             ←→ Push notifications               │
│  Foreground Svc  ←→ Call state monitoring             │
│  Overlay Window  ←→ System-wide risk display         │
│                                                       │
├─────────────────────────────────────────────────────┤
│                 BACKGROUND PROCESSES                  │
│                                                       │
│  Workmanager     → 12-hour scam DB sync              │
│  ClipboardMonitor→ Continuous URL scanning            │
│  CallStateSvc    → Incoming call detection            │
└─────────────────────────────────────────────────────┘
```

---

## 5.7 Security Architecture (Mobile)

| Layer | Mechanism | Implementation |
|-------|-----------|----------------|
| Transport | Certificate Pinning | SHA-256 fingerprints for api.fraudshieldprotect.com |
| Transport | HTTPS Only | `usesCleartextTraffic=false` in AndroidManifest |
| Storage | Token Encryption | FlutterSecureStorage with AES encryption |
| Replay | Anti-Replay Headers | X-Request-Timestamp + X-Request-Nonce on all requests |
| Auth | Token Refresh | Automatic refresh with deduplication on 401 |
| Device | Attestation | Google Play Integrity API validation post-login |
| Device | Jailbreak Detection | Runtime checks via flutter_jailbreak_detection |
| Access | Biometric Guard | Fingerprint/Face ID for premium features |
| Network | Timeout | Request timeout enforcement |

---

## 5.8 Design System

### Color Tokens
| Token | Hex | Usage |
|-------|-----|-------|
| Primary | #4F46E5 | Buttons, links, active states |
| Accent Green | #10B981 | Success, safe indicators |
| Background Dark | #0F172A | Dark mode background |
| Background Light | #F3F4F6 | Light mode background |
| Surface Dark | #1E293B | Cards in dark mode |
| Error | #EF4444 | Error states, high risk |
| Warning | #F59E0B | Medium risk, caution |
| Success | #10B981 | Low risk, verified |

### Typography Scale
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 48px | Bold | Splash, hero numbers |
| H1 | 36px | Bold | Screen titles |
| H2 | 28px | Bold | Section headers |
| H3 | 24px | Bold | Card titles |
| Body Large | 18px | Regular | Primary content |
| Body Medium | 16px | Regular | Secondary content |
| Body Small | 14px | Regular | Supporting text |
| Caption | 12px | Regular | Labels, timestamps |

### Spacing Scale
| Token | Value |
|-------|-------|
| xs | 4px |
| sm | 8px |
| md | 12px |
| lg | 16px |
| xl | 24px |
| xxl | 32px |
| xxxl | 48px |

---

## 5.9 Android Permissions

### Required Permissions
| Permission | Justification |
|-----------|--------------|
| `INTERNET` | API communication |
| `CAMERA` | QR scanning, device audit |
| `ACCESS_FINE_LOCATION` | Scam geolocation reporting |
| `ACCESS_COARSE_LOCATION` | Regional alert matching |
| `READ_PHONE_STATE` | Call monitoring (Android 10+) |
| `READ_PHONE_NUMBERS` | Number verification |
| `POST_NOTIFICATIONS` | Push notifications |
| `FOREGROUND_SERVICE` | Background call monitoring |
| `SYSTEM_ALERT_WINDOW` | Caller risk overlays |
| `WAKE_LOCK` | Background task execution |
| `RECORD_AUDIO` | Voice call analysis |
| `READ_CALL_LOG` | Android 9 and below only |

### Android Services
| Service | Type | Purpose |
|---------|------|---------|
| ForegroundService | phoneCall | Background call monitoring |
| CallScreeningService | — | Call interception (Android 10+) |
| NotificationListener | — | Smart capture feature |
| OverlayService | — | System-wide risk overlays |

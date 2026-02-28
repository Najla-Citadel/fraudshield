# FraudShield Frontend
    
This is the Flutter frontend application for FraudShield, a comprehensive scam detection and prevention platform.

## 📱 App Structure

The application is built using a feature-rich, scalable architecture designed for high performance and maintainability.

The core source code is located in the `lib` directory, organized as follows:

*   **`screens/`**: Contains all 44 UI screens, representing different pages in the app (e.g., `home_screen.dart`, `fraud_check_screen.dart`, `scam_reporting_screen.dart`, `community_feed_screen.dart`, `voice_detection_screen.dart`). 
*   **`widgets/`**: Reusable UI components (Atoms and Molecules) that ensure a consistent design system across the app.
*   **`services/`**: Encapsulates business logic and external communications (e.g., API calls, device integrations).
    *   `api_service.dart`: Main gateway for backend REST API communication.
    *   `risk_evaluator.dart`: Client-side logic for parsing and presenting risk scores.
    *   `notification_service.dart`: FCM integration for push notifications.
*   **`providers/`**: State management classes using the `provider` package.
    *   `auth_provider.dart`: Manages user authentication state, tokens, and session persistence.
    *   `theme_provider.dart`: Handles dynamic Light/Dark mode switching.
    *   `locale_provider.dart`: Manages app localization/language settings.
*   **`models/`**: Data classes representing objects like User, ScamReport, Badge, and Transaction.
*   **`l10n/`**: Localization files supporting multiple languages (English, Bahasa Malaysia, Chinese).
*   **`constants/`**: App-wide constants including colors, themes, API endpoints, and configuration flags.
*   **`utils/`**: Helper functions and generic utilities.
*   **`main.dart`**: The application entry point that initializes services, providers, and global configurations.
*   **`app_router.dart`**: Centralized route management and navigation logic.

---

## 🏗️ How the Frontend Works

### 1. State Management
FraudShield relies on the [`provider`](https://pub.dev/packages/provider) package for reactive state management. 
- At app launch, `main.dart` wraps the application in `MultiProvider`, injecting `AuthProvider`, `ThemeProvider`, and `LocaleProvider`.
- Widgets listen to these providers. For instance, when the user logs in, `AuthProvider` updates its state, immediately triggering a rebuild that navigates the user from the Login Screen to the Home Screen.

### 2. API Communication & Security
- **API Service**: All network requests to the local/production backend route through `api_service.dart`.
- **Token Management**: The app uses `flutter_secure_storage` to safely store JWT tokens on the device (Keychain for iOS, EncryptedSharedPreferences for Android).
- **Interceptors**: API calls automatically attach the stored Authorization `Bearer` token and handle token refresh flows or automatic logouts on session expiry.

### 3. Core Features & Navigation
- **Fraud Checks**: Users can input text, URLs, numbers, or upload files (PDFs, APKs). The frontend gathers this data and sends it to the backend via `api_service.dart`. Results are returned and displayed using `risk_evaluator.dart` to show a visual risk score and breakdown.
- **Reporting & Community**: The `community_feed_screen.dart` fetches a list of user-submitted scam reports. Users can submit new reports via the `scam_reporting_screen.dart`.
- **Gamification**: The app features a live badge and points system. Actions (like reporting a scam) trigger API calls that return points. The UI immediately reflects these changes, motivating user engagement.
- **Hardware Integration**: Screens like `qr_detection_screen.dart` and `voice_detection_screen.dart` actively use the device camera and microphone, processing local data streams before sending them for backend AI analysis.

### 4. Theming and Localization
- The app supports a custom sophisticated design. `theme_provider.dart` reads device preferences or user overrides to provide `ThemeData`.
- Flutter's localization (`flutter_localizations`) is tied to `locale_provider.dart`, allowing real-time language switching without restarting the app.

---

## 🚀 Getting Started Locally

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Set up `.env`**:
   Ensure you have a `.env` file in the root `fraudshield` directory pointing to your backend:
   ```env
   API_BASE_URL=http://10.0.2.2:3000/api/v1  # For Android Emulator
   # API_BASE_URL=http://localhost:3000/api/v1 # For iOS Simulator / Web
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

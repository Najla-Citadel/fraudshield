import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FraudShield'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get navRewards;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @btnScan.
  ///
  /// In en, this message translates to:
  /// **'Scan Now'**
  String get btnScan;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @fraudCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Fraud Check'**
  String get fraudCheckTitle;

  /// No description provided for @voiceScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Analysis'**
  String get voiceScanTitle;

  /// No description provided for @scamReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Scam'**
  String get scamReportTitle;

  /// No description provided for @riskLevelSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get riskLevelSafe;

  /// No description provided for @riskLevelSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious'**
  String get riskLevelSuspicious;

  /// No description provided for @riskLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get riskLevelHigh;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get homeGreetingEvening;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Security Center'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'This score represents your current defense level. Tapping the ring shows a detailed security report and how to improve your score to 100.'**
  String get homeWelcomeDesc;

  /// No description provided for @homeWelcomeBtn.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get homeWelcomeBtn;

  /// No description provided for @homeRecentChecks.
  ///
  /// In en, this message translates to:
  /// **'RECENT CHECKS'**
  String get homeRecentChecks;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @homeNoRecentScans.
  ///
  /// In en, this message translates to:
  /// **'No recent scans recorded.'**
  String get homeNoRecentScans;

  /// No description provided for @homeThreatInsights.
  ///
  /// In en, this message translates to:
  /// **'THREAT INSIGHTS'**
  String get homeThreatInsights;

  /// No description provided for @accountMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountMyAccount;

  /// No description provided for @accountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get accountPreferences;

  /// No description provided for @accountTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountTheme;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountNotifications;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountSecurity;

  /// No description provided for @accountHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get accountHelp;

  /// No description provided for @accountLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get accountLogout;

  /// No description provided for @accountSubscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get accountSubscriptionPlan;

  /// No description provided for @accountFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get accountFree;

  /// No description provided for @accountPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get accountPremium;

  /// No description provided for @accountDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get accountDarkMode;

  /// No description provided for @accountNotificationSetting.
  ///
  /// In en, this message translates to:
  /// **'Notification Setting'**
  String get accountNotificationSetting;

  /// No description provided for @accountSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountSecurityTitle;

  /// No description provided for @accountTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Auth'**
  String get accountTwoFactor;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountChangePassword;

  /// No description provided for @accountPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get accountPrivacyPolicy;

  /// No description provided for @fraudThinkScam.
  ///
  /// In en, this message translates to:
  /// **'Think it might be a scam?'**
  String get fraudThinkScam;

  /// No description provided for @fraudAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant AI-powered fraud detection'**
  String get fraudAiDesc;

  /// No description provided for @fraudSmartInput.
  ///
  /// In en, this message translates to:
  /// **'Smart Input'**
  String get fraudSmartInput;

  /// No description provided for @fraudDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get fraudDetected;

  /// No description provided for @fraudPhoneBankDetected.
  ///
  /// In en, this message translates to:
  /// **'Phone/Bank Detected'**
  String get fraudPhoneBankDetected;

  /// No description provided for @fraudHint.
  ///
  /// In en, this message translates to:
  /// **'Paste phone, account, URL, or message...'**
  String get fraudHint;

  /// No description provided for @fraudUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get fraudUploadFile;

  /// No description provided for @fraudPdfApk.
  ///
  /// In en, this message translates to:
  /// **'PDF or APK'**
  String get fraudPdfApk;

  /// No description provided for @fraudScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get fraudScanQr;

  /// No description provided for @fraudCameraCheck.
  ///
  /// In en, this message translates to:
  /// **'Camera check'**
  String get fraudCameraCheck;

  /// No description provided for @fraudCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check Now'**
  String get fraudCheckNow;

  /// No description provided for @fraudAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get fraudAnalyze;

  /// No description provided for @fraudStayProtected.
  ///
  /// In en, this message translates to:
  /// **'Stay Protected'**
  String get fraudStayProtected;

  /// No description provided for @fraudCheckResult.
  ///
  /// In en, this message translates to:
  /// **'Check Result'**
  String get fraudCheckResult;

  /// No description provided for @fraudCriticalThreat.
  ///
  /// In en, this message translates to:
  /// **'Critical Threat'**
  String get fraudCriticalThreat;

  /// No description provided for @fraudHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get fraudHighRisk;

  /// No description provided for @fraudLooksSafe.
  ///
  /// In en, this message translates to:
  /// **'Looks Safe'**
  String get fraudLooksSafe;

  /// No description provided for @fraudSafeDesc.
  ///
  /// In en, this message translates to:
  /// **'No threats found. Appears to be safe.'**
  String get fraudSafeDesc;

  /// No description provided for @reportStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Scammer Identity'**
  String get reportStepIdentity;

  /// No description provided for @reportStepCategory.
  ///
  /// In en, this message translates to:
  /// **'Scam Category'**
  String get reportStepCategory;

  /// No description provided for @reportStepStory.
  ///
  /// In en, this message translates to:
  /// **'The Story'**
  String get reportStepStory;

  /// No description provided for @reportStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reportStepReview;

  /// No description provided for @reportIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'What information do you have?'**
  String get reportIdentityTitle;

  /// No description provided for @reportIdentityDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the main identifier for the scammer.'**
  String get reportIdentityDesc;

  /// No description provided for @reportLabelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get reportLabelPhone;

  /// No description provided for @reportLabelBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get reportLabelBank;

  /// No description provided for @reportLabelSocial.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get reportLabelSocial;

  /// No description provided for @reportLabelWeb.
  ///
  /// In en, this message translates to:
  /// **'Website / App'**
  String get reportLabelWeb;

  /// No description provided for @reportLabelOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get reportLabelOthers;

  /// No description provided for @reportFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Scammer Phone Number'**
  String get reportFieldPhone;

  /// No description provided for @reportFieldBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get reportFieldBank;

  /// No description provided for @reportFieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get reportFieldAccount;

  /// No description provided for @reportFieldPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform (e.g. FB, Telegram)'**
  String get reportFieldPlatform;

  /// No description provided for @reportFieldHandle.
  ///
  /// In en, this message translates to:
  /// **'Handle / Username'**
  String get reportFieldHandle;

  /// No description provided for @reportFieldWeb.
  ///
  /// In en, this message translates to:
  /// **'Website URL / App Link'**
  String get reportFieldWeb;

  /// No description provided for @reportCatInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment Scam'**
  String get reportCatInvestment;

  /// No description provided for @reportCatPhishing.
  ///
  /// In en, this message translates to:
  /// **'Phishing Scam'**
  String get reportCatPhishing;

  /// No description provided for @reportCatJob.
  ///
  /// In en, this message translates to:
  /// **'Job Scam'**
  String get reportCatJob;

  /// No description provided for @reportCatLove.
  ///
  /// In en, this message translates to:
  /// **'Love Scam'**
  String get reportCatLove;

  /// No description provided for @reportCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping Scam'**
  String get reportCatShopping;

  /// No description provided for @reportStoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened...'**
  String get reportStoryDesc;

  /// No description provided for @reportStoryLocation.
  ///
  /// In en, this message translates to:
  /// **'City / State (Optional)'**
  String get reportStoryLocation;

  /// No description provided for @reportEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Screenshot or Evidence'**
  String get reportEvidenceTitle;

  /// No description provided for @reportEvidenceLimits.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF (Max 5MB)'**
  String get reportEvidenceLimits;

  /// No description provided for @reportFinalReview.
  ///
  /// In en, this message translates to:
  /// **'Final Review'**
  String get reportFinalReview;

  /// No description provided for @reportShareCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share with Community'**
  String get reportShareCommunity;

  /// No description provided for @reportShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide your identity while helping others.'**
  String get reportShareDesc;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted!'**
  String get reportSubmitted;

  /// No description provided for @reportSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Thank you for keeping the community safe. We will verify your report shortly.'**
  String get reportSuccessDesc;

  /// No description provided for @homeVoiceCheck.
  ///
  /// In en, this message translates to:
  /// **'Voice Check'**
  String get homeVoiceCheck;

  /// No description provided for @homeMessageScan.
  ///
  /// In en, this message translates to:
  /// **'AI Message Scanner'**
  String get homeMessageScan;

  /// No description provided for @homeUnlockVoice.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock Voice Check!'**
  String get homeUnlockVoice;

  /// No description provided for @homeUnlockPhishing.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock Phishing Protection!'**
  String get homeUnlockPhishing;

  /// No description provided for @homeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE'**
  String get homeUpgrade;

  /// No description provided for @homeTrendingThreats.
  ///
  /// In en, this message translates to:
  /// **'TRENDING THREATS'**
  String get homeTrendingThreats;

  /// No description provided for @homeTrendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay ahead of the latest scams in your area. Check the threat intelligence dashboard now.'**
  String get homeTrendingDesc;

  /// No description provided for @homeSystemActive.
  ///
  /// In en, this message translates to:
  /// **'System Shield Active'**
  String get homeSystemActive;

  /// No description provided for @homePaymentJournal.
  ///
  /// In en, this message translates to:
  /// **'Payment Journal'**
  String get homePaymentJournal;

  /// No description provided for @statusExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get statusExcellent;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get statusProtected;

  /// No description provided for @statusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get statusAtRisk;

  /// No description provided for @homeServices.
  ///
  /// In en, this message translates to:
  /// **'SERVICES'**
  String get homeServices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

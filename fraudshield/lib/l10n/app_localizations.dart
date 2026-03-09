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
  /// **'Paste phone or bank account number...'**
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

  /// No description provided for @fraudTipOtp.
  ///
  /// In en, this message translates to:
  /// **'Never share your OTP or banking details'**
  String get fraudTipOtp;

  /// No description provided for @fraudTipVerify.
  ///
  /// In en, this message translates to:
  /// **'Always verify official website URLs'**
  String get fraudTipVerify;

  /// No description provided for @fraudTipReport.
  ///
  /// In en, this message translates to:
  /// **'Report suspicious activity immediately'**
  String get fraudTipReport;

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
  /// **'AI Voice Scanner'**
  String get homeVoiceCheck;

  /// No description provided for @homeMessageScan.
  ///
  /// In en, this message translates to:
  /// **'AI Message Scanner'**
  String get homeMessageScan;

  /// No description provided for @homeUnlockVoice.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock AI Voice Scanner!'**
  String get homeUnlockVoice;

  /// No description provided for @homeUnlockPhishing.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock AI File Scanner!'**
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

  /// No description provided for @accountPrivacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get accountPrivacySettings;

  /// No description provided for @privacyManageConsent.
  ///
  /// In en, this message translates to:
  /// **'Manage Consent'**
  String get privacyManageConsent;

  /// No description provided for @privacyDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get privacyDataManagement;

  /// No description provided for @privacyRequestDataExport.
  ///
  /// In en, this message translates to:
  /// **'Request Data Export'**
  String get privacyRequestDataExport;

  /// No description provided for @privacyUpdateInfo.
  ///
  /// In en, this message translates to:
  /// **'Update/Correct Information'**
  String get privacyUpdateInfo;

  /// No description provided for @privacyWithdrawConsent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Consent'**
  String get privacyWithdrawConsent;

  /// No description provided for @privacyConsentMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing & Newsletters'**
  String get privacyConsentMarketing;

  /// No description provided for @privacyDpoContact.
  ///
  /// In en, this message translates to:
  /// **'Contact DPO'**
  String get privacyDpoContact;

  /// No description provided for @privacyControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Take control of your personal data in compliance with PDPA 2010.'**
  String get privacyControlDesc;

  /// No description provided for @privacyWithdrawDesc.
  ///
  /// In en, this message translates to:
  /// **'Retract consent for non-essential services.'**
  String get privacyWithdrawDesc;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSignInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to FraudShield'**
  String get loginSignInDesc;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @navBoard.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get navBoard;

  /// No description provided for @homeCustomizeServices.
  ///
  /// In en, this message translates to:
  /// **'Customize Services'**
  String get homeCustomizeServices;

  /// No description provided for @homeSelectActionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Select which actions to display on your dashboard.'**
  String get homeSelectActionsDesc;

  /// No description provided for @btnDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get btnDone;

  /// No description provided for @btnLogNow.
  ///
  /// In en, this message translates to:
  /// **'Log Now'**
  String get btnLogNow;

  /// No description provided for @homeQuickProtection.
  ///
  /// In en, this message translates to:
  /// **'Quick Protection'**
  String get homeQuickProtection;

  /// No description provided for @homeSecurityHealthScore.
  ///
  /// In en, this message translates to:
  /// **'SECURITY HEALTH SCORE'**
  String get homeSecurityHealthScore;

  /// No description provided for @homeEnvironmentProtected.
  ///
  /// In en, this message translates to:
  /// **'Environment Protected'**
  String get homeEnvironmentProtected;

  /// No description provided for @homeSecurityNews.
  ///
  /// In en, this message translates to:
  /// **'Security News'**
  String get homeSecurityNews;

  /// No description provided for @homeMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get homeMyReports;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @fraudAiAnalysisResult.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Result'**
  String get fraudAiAnalysisResult;

  /// No description provided for @fraudEnterContentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter content to check'**
  String get fraudEnterContentPrompt;

  /// No description provided for @fraudRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get fraudRecentActivity;

  /// No description provided for @btnClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get btnClear;

  /// No description provided for @homePremiumProtection.
  ///
  /// In en, this message translates to:
  /// **'Premium Protection'**
  String get homePremiumProtection;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOr;

  /// No description provided for @homeSecurityReport.
  ///
  /// In en, this message translates to:
  /// **'Security Report'**
  String get homeSecurityReport;

  /// No description provided for @homeProfileSecurity.
  ///
  /// In en, this message translates to:
  /// **'Profile Security'**
  String get homeProfileSecurity;

  /// No description provided for @homeProfileSafeDesc.
  ///
  /// In en, this message translates to:
  /// **'Profile information is up to date.'**
  String get homeProfileSafeDesc;

  /// No description provided for @homeProfileAtRiskDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to improve security.'**
  String get homeProfileAtRiskDesc;

  /// No description provided for @btnUpdate.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get btnUpdate;

  /// No description provided for @homeActiveDefenses.
  ///
  /// In en, this message translates to:
  /// **'Active Defenses'**
  String get homeActiveDefenses;

  /// No description provided for @homeActiveDefensesDesc.
  ///
  /// In en, this message translates to:
  /// **'protection layers active.'**
  String get homeActiveDefensesDesc;

  /// No description provided for @btnEnable.
  ///
  /// In en, this message translates to:
  /// **'ENABLE'**
  String get btnEnable;

  /// No description provided for @homePremiumAdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Advanced AI shields are active.'**
  String get homePremiumAdvancedDesc;

  /// No description provided for @homePremiumUpgradeDesc.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock full protection.'**
  String get homePremiumUpgradeDesc;

  /// No description provided for @btnUnlock.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK'**
  String get btnUnlock;

  /// No description provided for @newsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fraud Intelligence'**
  String get newsTitle;

  /// No description provided for @newsReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get newsReadMore;

  /// No description provided for @newsLatestUpdate.
  ///
  /// In en, this message translates to:
  /// **'Latest Update'**
  String get newsLatestUpdate;

  /// No description provided for @accountSmartCapture.
  ///
  /// In en, this message translates to:
  /// **'Smart Capture (Beta)'**
  String get accountSmartCapture;

  /// No description provided for @accountSmartCaptureDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-log banking transactions'**
  String get accountSmartCaptureDesc;

  /// No description provided for @accountCallerId.
  ///
  /// In en, this message translates to:
  /// **'Caller ID Protection'**
  String get accountCallerId;

  /// No description provided for @accountCallerIdDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time scam detection in calls'**
  String get accountCallerIdDesc;

  /// No description provided for @accountDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDeleteAccount;

  /// No description provided for @accountChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get accountChangePasswordTitle;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get accountCurrentPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get accountNewPassword;

  /// No description provided for @btnUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get btnUpdatePassword;

  /// No description provided for @accountBiometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get accountBiometricAuth;

  /// No description provided for @accountLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get accountLegalTitle;

  /// No description provided for @accountTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get accountTermsOfService;

  /// No description provided for @accountManageConsent.
  ///
  /// In en, this message translates to:
  /// **'Manage Consent'**
  String get accountManageConsent;

  /// No description provided for @accountSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get accountSelectLanguage;

  /// No description provided for @accountViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get accountViewProfile;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profilePreferredName.
  ///
  /// In en, this message translates to:
  /// **'Preferred Name'**
  String get profilePreferredName;

  /// No description provided for @profilePreferredNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get profilePreferredNameHint;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @accountSimulateBankingAlert.
  ///
  /// In en, this message translates to:
  /// **'Simulate Banking Alert'**
  String get accountSimulateBankingAlert;

  /// No description provided for @accountSimulateBankingDesc.
  ///
  /// In en, this message translates to:
  /// **'Test auto-capture logic'**
  String get accountSimulateBankingDesc;

  /// No description provided for @accountSimulateIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Simulate Incoming Call'**
  String get accountSimulateIncomingCall;

  /// No description provided for @accountSimulateIncomingCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Test Caller ID Overlay'**
  String get accountSimulateIncomingCallDesc;

  /// No description provided for @accountLogTestTransaction.
  ///
  /// In en, this message translates to:
  /// **'Log Test Transaction'**
  String get accountLogTestTransaction;

  /// No description provided for @accountTransactionJournal.
  ///
  /// In en, this message translates to:
  /// **'Transaction Journal'**
  String get accountTransactionJournal;

  /// No description provided for @accountVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get accountVersion;

  /// No description provided for @subRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String subRenewsOn(String date);

  /// No description provided for @subActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get subActive;

  /// No description provided for @subWelcomePremium.
  ///
  /// In en, this message translates to:
  /// **'🎉 Welcome to Premium!'**
  String get subWelcomePremium;

  /// No description provided for @subHeaderNextGen.
  ///
  /// In en, this message translates to:
  /// **'Next-gen AI protection for your digital wealth.'**
  String get subHeaderNextGen;

  /// No description provided for @subPremiumMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Premium Member!'**
  String get subPremiumMember;

  /// No description provided for @subManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get subManageSubscription;

  /// No description provided for @subCancelModify.
  ///
  /// In en, this message translates to:
  /// **'Cancel or modify at any time'**
  String get subCancelModify;

  /// No description provided for @subMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subMonthly;

  /// No description provided for @subYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subYearly;

  /// No description provided for @subSave20.
  ///
  /// In en, this message translates to:
  /// **'SAVE 20%'**
  String get subSave20;

  /// No description provided for @subPopular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get subPopular;

  /// No description provided for @subBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get subBilledMonthly;

  /// No description provided for @subBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'Billed {price} yearly'**
  String subBilledYearly(String price);

  /// No description provided for @subPremiumDescShort.
  ///
  /// In en, this message translates to:
  /// **'Complete AI-powered protection with real-time alerts.'**
  String get subPremiumDescShort;

  /// No description provided for @subBasicDescShort.
  ///
  /// In en, this message translates to:
  /// **'Basic protection for everyday use.'**
  String get subBasicDescShort;

  /// No description provided for @subCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get subCurrentPlan;

  /// No description provided for @subGetPremium.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get subGetPremium;

  /// No description provided for @subUpgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get subUpgradeToPremium;

  /// No description provided for @subFeatureComparison.
  ///
  /// In en, this message translates to:
  /// **'FEATURE COMPARISON'**
  String get subFeatureComparison;

  /// No description provided for @subFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get subFree;
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

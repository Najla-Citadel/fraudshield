import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import '../widgets/adaptive_text_field.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/tokens/typography.dart';
import '../widgets/settings_group.dart';
import 'subscription_screen.dart' as crate;
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_snackbar.dart';
import 'status_details_screen.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'transaction_journal_screen.dart';
import 'profile_screen.dart';
import 'alert_preferences_screen.dart';
import '../services/biometric_service.dart';
import '../services/smart_capture_service.dart';
import '../services/call_state_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'log_payment_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ================= STATE =================
  bool _loading = true;
  bool _hasError = false;
  String _avatarSeed = 'Felix';
  bool _biometricEnabled = false;
  bool _isBiometricAvailable = false;
  bool _smartCaptureEnabled = false;
  bool _callerIdProtectionEnabled = false;

  // ================= LIFECYCLE =================
  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkBiometrics();
    _loadSmartCaptureState();
    _loadCallerIdProtectionState();
  }

  Future<void> _loadSmartCaptureState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('smart_capture_enabled') ?? false;
    if (enabled) {
      await SmartCaptureService().start();
    }
    if (mounted) {
      setState(() => _smartCaptureEnabled = enabled);
    }
  }

  Future<void> _toggleSmartCapture(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_capture_enabled', enabled);

    if (enabled) {
      try {
        bool hasPermission =
            await NotificationListenerService.isPermissionGranted();
        if (!hasPermission) {
          _toast('Please enable FraudShield in Notification Access settings');
          await SmartCaptureService.requestPermission();
        }
      } catch (e) {
        debugPrint('AccountScreen: Error checking notification permission: $e');
      }
      await SmartCaptureService().start();
    } else {
      await SmartCaptureService().stop();
    }

    if (mounted) {
      setState(() => _smartCaptureEnabled = enabled);
    }
  }

  Future<void> _loadCallerIdProtectionState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('caller_id_protection_enabled') ?? false;
    if (enabled) {
      CallStateService.instance.startProtection();
    }
    if (mounted) {
      setState(() => _callerIdProtectionEnabled = enabled);
    }
  }

  Future<void> _toggleCallerIdProtection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('caller_id_protection_enabled', enabled);

    if (enabled) {
      if (!await Permission.systemAlertWindow.isGranted) {
        await Permission.systemAlertWindow.request();
      }
      await CallStateService.instance.startProtection();
    } else {
      await CallStateService.instance.stopProtection();
    }

    if (mounted) {
      setState(() => _callerIdProtectionEnabled = enabled);
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ================= DATA =================
  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    if (profile == null) {
      // Clear flag to avoid infinite loops if it fails persistently
      await authProvider.refreshProfile().catchError((_) => null);
    }

    if (!mounted) return;

    final updatedProfile = authProvider.userProfile;
    _avatarSeed = updatedProfile?.profile?.avatar ?? 'Felix';

    setState(() {
      _loading = false;
      _hasError = false;
    });
  }

  Future<void> _saveAvatar(String seed) async {
    setState(() => _avatarSeed = seed);

    try {
      await ApiService.instance.updateProfile(avatar: seed);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshProfile();
    } catch (e) {
      log('Error saving avatar: $e');
      _toast('Failed to update avatar', isError: true);
    }
  }

  // ================= NAVIGATION =================
  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPicker(
        selected: _avatarSeed,
        onSelect: (seed) async {
          Navigator.pop(context);
          await _saveAvatar(seed);
        },
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _toast(String msg, {bool isError = false}) {
    if (isError) {
      AppSnackBar.showError(context, msg);
    } else {
      AppSnackBar.showInfo(context, msg);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ScreenScaffold(
        title: 'Account',
        body: ErrorState(onRetry: () {
          setState(() {
            _loading = true;
            _hasError = false;
          });
          _loadProfile();
        }),
      );
    }

    final colors = DesignTokens.colors;

    if (_loading) {
      return ScreenScaffold(
        title: 'Account',
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
          child: Column(
            children: [
              SizedBox(height: 24),
              SkeletonCard(height: 250, margin: EdgeInsets.zero),
              SizedBox(height: 24),
              SkeletonCard(height: 150, margin: EdgeInsets.zero),
              SizedBox(height: 24),
              SkeletonCard(height: 150, margin: EdgeInsets.zero),
            ],
          ),
        ),
      );
    }

    return ScreenScaffold(
      title: 'Account',
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: colors.primary,
        backgroundColor: colors.surfaceDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 100),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  SizedBox(height: 20),
                  _premiumProfileHeader(),
                  SizedBox(height: 16),
                  _statisticsCard(),
                  SizedBox(height: 24),

                  // Preferences
                  SettingsGroup(
                    title: AppLocalizations.of(context)!.accountPreferences,
                    margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.md),
                    items: [
                      SettingsTile(
                        icon: LucideIcons.award,
                        title: AppLocalizations.of(context)!.accountSubscriptionPlan,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.watch<AuthProvider>().isSubscribed
                                  ? AppLocalizations.of(context)!.accountPremium
                                  : AppLocalizations.of(context)!.accountFree,
                              style: TextStyle(
                                color: context.watch<AuthProvider>().isSubscribed
                                    ? Colors.amber
                                    : colors.textLight.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronRight,
                              color: colors.textLight.withValues(alpha: 0.2),
                              size: 14,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const crate.SubscriptionScreen()),
                        ),
                      ),
                      SettingsTile(
                        icon: LucideIcons.bellRing,
                        title: AppLocalizations.of(context)!.accountNotificationSetting,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AlertPreferencesScreen()),
                        ),
                      ),
                      SettingsTile(
                        icon: LucideIcons.globe,
                        title: AppLocalizations.of(context)!.accountLanguage,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.watch<LocaleProvider>().locale?.languageCode == 'ms'
                                  ? 'Bahasa Malaysia'
                                  : 'English',
                              style: TextStyle(
                                color: colors.textLight.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronRight,
                              color: colors.textLight.withValues(alpha: 0.2),
                              size: 14,
                            ),
                          ],
                        ),
                        onTap: _showLanguagePicker,
                      ),
                      SettingsTile(
                        icon: LucideIcons.sparkles,
                        title: AppLocalizations.of(context)!.accountSmartCapture,
                        subtitle: AppLocalizations.of(context)!.accountSmartCaptureDesc,
                        onTap: () {},
                        trailing: Switch(
                          value: _smartCaptureEnabled,
                          onChanged: _toggleSmartCapture,
                          activeThumbColor: colors.accentGreen,
                        ),
                      ),
                      SettingsTile(
                        icon: LucideIcons.shield,
                        title: AppLocalizations.of(context)!.accountCallerId,
                        subtitle: AppLocalizations.of(context)!.accountCallerIdDesc,
                        onTap: () {},
                        trailing: Switch(
                          value: _callerIdProtectionEnabled,
                          onChanged: _toggleCallerIdProtection,
                          activeThumbColor: colors.accentGreen,
                        ),
                      ),
                      if (_smartCaptureEnabled || _callerIdProtectionEnabled) ...[
                        if (_smartCaptureEnabled)
                          SettingsTile(
                            icon: LucideIcons.bug,
                            title: AppLocalizations.of(context)!.accountSimulateBankingAlert,
                            subtitle: AppLocalizations.of(context)!.accountSimulateBankingDesc,
                            onTap: () async {
                              const testText = 'RM 1250.00 transferred to MULE_ACC_123';
                              try {
                                await NotificationService.instance.showNotification(
                                  title: 'MAE Alert',
                                  body: testText,
                                );
                              } catch (e) {
                                debugPrint('Visual notification failed: $e');
                              }
                              try {
                                await SmartCaptureService().simulateCapture(testText);
                                if (mounted) _toast('Simulation complete!');
                              } catch (e) {
                                if (mounted) _toast('Capture failed.', isError: true);
                              }
                            },
                          ),
                        if (_callerIdProtectionEnabled)
                          SettingsTile(
                            icon: LucideIcons.phoneIncoming,
                            title: AppLocalizations.of(context)!.accountSimulateIncomingCall,
                            subtitle: AppLocalizations.of(context)!.accountSimulateIncomingCallDesc,
                            onTap: () async {
                              _toast('Simulating incoming call...');
                              CallStateService.instance.simulateRinging('0123456789');
                            },
                          ),
                      ],
                      SettingsTile(
                        icon: LucideIcons.plusCircle,
                        title: AppLocalizations.of(context)!.accountLogTestTransaction,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => LogPaymentSheet(
                              onLogSuccess: () => _toast('Transaction logged successfully!'),
                            ),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: LucideIcons.fileText,
                        title: AppLocalizations.of(context)!.accountTransactionJournal,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TransactionJournalScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  // Security
                  SettingsGroup(
                    title: AppLocalizations.of(context)!.accountSecurityTitle,
                    margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.md),
                    items: [
                      SettingsTile(
                        icon: LucideIcons.lock,
                        title: AppLocalizations.of(context)!.accountChangePassword,
                        onTap: _openChangePassword,
                      ),
                      if (_isBiometricAvailable)
                        SettingsTile(
                          icon: LucideIcons.fingerprint,
                          title: AppLocalizations.of(context)!.accountBiometricAuth,
                          subtitle: 'Extra security for sensitive actions',
                          onTap: () {},
                          trailing: Switch(
                            value: _biometricEnabled,
                            onChanged: (val) async {
                              await BiometricService.instance.setEnabled(val);
                              setState(() => _biometricEnabled = val);
                            },
                            activeThumbColor: colors.accentGreen,
                          ),
                        ),
                    ],
                  ),

                  // Legal
                  SettingsGroup(
                    title: AppLocalizations.of(context)!.accountLegalTitle,
                    margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.md),
                    items: [
                      SettingsTile(
                        icon: LucideIcons.shieldQuestion,
                        title: AppLocalizations.of(context)!.accountPrivacyPolicy,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                      ),
                      SettingsTile(
                        icon: LucideIcons.fileText,
                        title: AppLocalizations.of(context)!.accountTermsOfService,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
                      ),
                      SettingsTile(
                        icon: LucideIcons.gavel,
                        title: AppLocalizations.of(context)!.accountManageConsent,
                        trailing: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textLight.withValues(alpha: 0.2),
                          size: 14,
                        ),
                        onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _logoutButton(),
                  Padding(
                    padding: EdgeInsets.only(top: DesignTokens.spacing.md),
                    child: TextButton(
                      onPressed: _confirmDeleteAccount,
                      child: Text(
                        AppLocalizations.of(context)!.accountDeleteAccount,
                        style: TextStyle(
                          color: colors.error.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    '${AppLocalizations.of(context)!.accountVersion} 1.1.0',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textLight.withValues(alpha: 0.05),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // =================PASSWORD===================
  void _openChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = DesignTokens.colors;
            return Padding(
              padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xxl, DesignTokens.spacing.xxl, DesignTokens.spacing.xxl, MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.accountChangePasswordTitle,
                    style: DesignTypography.h3,
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: colors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 16),
                  AdaptiveTextField(
                    controller: currentCtrl,
                    label: AppLocalizations.of(context)!.accountCurrentPassword,
                    obscureText: true,
                  ),
                  SizedBox(height: 12),
                  AdaptiveTextField(
                    controller: newCtrl,
                    label: AppLocalizations.of(context)!.accountNewPassword,
                    obscureText: true,
                  ),
                  SizedBox(height: DesignTokens.spacing.xxl),
                  AppButton(
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            final current = currentCtrl.text.trim();
                            final next = newCtrl.text.trim();

                            setSheetState(() => errorMessage = null);

                            if (current.isEmpty) {
                              setSheetState(() => errorMessage =
                                  'Please enter your current password');
                              return;
                            }
                            if (next.isEmpty) {
                              setSheetState(() =>
                                  errorMessage = 'Please enter a new password');
                              return;
                            }
                            if (next.length < 8) {
                              setSheetState(() => errorMessage =
                                  'New password must be at least 8 characters');
                              return;
                            }
                            if (!next.contains(RegExp(r'[A-Z]'))) {
                              setSheetState(() => errorMessage =
                                  'New password must contain an uppercase letter');
                              return;
                            }
                            if (!next.contains(RegExp(r'[0-9]'))) {
                              setSheetState(() => errorMessage =
                                  'New password must contain a number');
                              return;
                            }

                            setSheetState(() => isLoading = true);

                             ApiService.instance
                                .changePassword(current, next)
                                .then((_) {
                              if (mounted && sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                                _toast('Password updated successfully');
                              }
                            }).catchError((e) {
                              if (mounted) {
                                setSheetState(() {
                                  isLoading = false;
                                  errorMessage = e.toString().contains('400')
                                      ? 'Incorrect current password'
                                      : 'Failed to update password';
                                });
                              }
                            });
                          },
                    label: AppLocalizations.of(context)!.btnUpdatePassword,
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.colors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final localeProvider = context.watch<LocaleProvider>();
        final currentLocale = localeProvider.locale?.languageCode ?? 'en';

        return Padding(
          padding: EdgeInsets.all(DesignTokens.spacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.accountSelectLanguage,
                style: DesignTypography.h3,
              ),
              SizedBox(height: 24),
              _buildLanguageItem('English', 'en', currentLocale == 'en', () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(context);
              }),
              _buildLanguageItem('Bahasa Malaysia', 'ms', currentLocale == 'ms',
                  () {
                localeProvider.setLocale(const Locale('ms'));
                Navigator.pop(context);
              }),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(
      String name, String code, bool isSelected, VoidCallback onTap) {
    final colors = DesignTokens.colors;
    return ListTile(
      onTap: onTap,
      leading: Text(code == 'en' ? '🇺🇸' : '🇲🇾',
          style: const TextStyle(fontSize: 24)),
      title: Text(name, style: TextStyle(color: colors.textLight)),
      trailing: isSelected
          ? Icon(LucideIcons.checkCircle2, color: DesignTokens.colors.accentGreen)
          : null,
    );
  }

  // ================= COMPONENTS =================

  Widget _premiumProfileHeader() {
    final colors = DesignTokens.colors;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          // Avatar
          GestureDetector(
            onTap: _openAvatarPicker,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacing.xs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: colors.textLight.withValues(alpha: 0.1), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF1E293B),
                    backgroundImage: NetworkImage(
                      'https://api.dicebear.com/7.x/avataaars/png?seed=$_avatarSeed',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignTokens.colors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                    child: Icon(LucideIcons.camera,
                        color: colors.textLight, size: 14),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Name and View Profile
          Column(
            children: [
              Text(
                user?.fullName ?? 'Alexander Wright',
                style: DesignTypography.h2,
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: DesignTokens.spacing.xs),
                  decoration: BoxDecoration(
                    color: colors.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                  ),
                    child: Text(
                      AppLocalizations.of(context)!.accountViewProfile,
                      style: TextStyle(
                        color: DesignTokens.colors.accentGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _statisticsCard() {
    final colors = DesignTokens.colors;
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.user?.profile;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacing.xxl),
        decoration: BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
          border: Border.all(color: colors.textLight.withValues(alpha: 0.05)),
          boxShadow: DesignTokens.shadows.md,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tier Badge
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StatusDetailsScreen()),
                  ),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: DesignTokens.spacing.sm),
                    decoration: BoxDecoration(
                      color: colors.textLight,
                      borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded,
                            color: Colors.black, size: 14),
                        SizedBox(width: 8),
                        Text(
                          _calculateTierName(profile?.totalPoints ?? 0),
                          style: TextStyle(
                            color: colors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Benefits and Plan Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plan Indicator
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const crate.SubscriptionScreen()),
                  ),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: DesignTokens.spacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          context.watch<AuthProvider>().isSubscribed
                              ? Icons.auto_awesome
                              : Icons.person_outline,
                          color: context.watch<AuthProvider>().isSubscribed
                              ? Colors.amber
                              : colors.textLight.withValues(alpha: 0.4),
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Text(
                          context.watch<AuthProvider>().isSubscribed
                              ? 'Premium Protector'
                              : 'Free Plan',
                          style: TextStyle(
                            color: context.watch<AuthProvider>().isSubscribed
                                ? Colors.amber
                                : colors.textLight.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // View Benefits Link
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StatusDetailsScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Benefits',
                        style: TextStyle(
                          color: DesignTokens.colors.accentGreen.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          color: colors.accentGreen.withValues(alpha: 0.8),
                          size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl),
      child: AppButton(
        label: 'Log Out',
        onPressed: _logout,
        variant: AppButtonVariant.destructive,
        width: double.infinity,
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final colors = DesignTokens.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        title: Text('Delete Account?',
            style: TextStyle(color: colors.textLight)),
        content: Text(
          'This action cannot be undone. Your profile and personal data will be permanently removed. Your reports will remain anonymized.',
          style: TextStyle(color: colors.textLight.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _executeAccountDeletion();
    }
  }

  Future<void> _executeAccountDeletion() async {
    setState(() => _loading = true);
    try {
      await ApiService.instance.deleteAccount();
      // Logout and redirect
      if (!mounted) return;
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      _toast('Account deleted successfully');
    } catch (e) {
      log('Error deleting account: $e');
      if (mounted) setState(() => _loading = false);
      _toast('Failed to delete account: $e', isError: true);
    }
  }

  String _calculateTierName(int totalPoints) {
    if (totalPoints >= 10000) return 'DIAMOND PROTECTOR';
    if (totalPoints >= 5000) return 'GOLD PROTECTOR';
    if (totalPoints >= 1000) return 'SILVER PROTECTOR';
    return 'BRONZE PROTECTOR';
  }

  // Removed _getBadgeEmoji as it is unused
}

// ================= AVATAR PICKER =================
class _AvatarPicker extends StatelessWidget {
  final String selected;
  final Function(String) onSelect;

  const _AvatarPicker({required this.selected, required this.onSelect});

  static const _seeds = [
    'Felix',
    'Aneka',
    'Caleb',
    'Jocelyn',
    'Max',
    'Luna',
    'Kellan',
    'Najla'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _seeds.map((seed) {
          final isSelected = selected == seed;
          return GestureDetector(
            onTap: () => onSelect(seed),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 3)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radii.md),
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=$seed',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                        child: AppLoadingIndicator(
                            color: DesignTokens.colors.primary, size: 20));
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

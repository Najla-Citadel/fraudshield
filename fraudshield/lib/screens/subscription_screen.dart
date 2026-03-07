import 'dart:ui';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/layouts/screen_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/typography.dart';
import '../design_system/components/app_snackbar.dart';
import '../design_system/components/app_divider.dart';
import '../l10n/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _api = ApiService.instance;

  bool _loading = true;
  bool _isSubscribing = false;
  bool _isYearly = false;
  Map<String, dynamic>? _activeSub;
  List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'Basic',
      'price': 0,
      'features': ['Community Reports', 'AI SMS Blocking'],
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': 9.90,
      'priceYearly': 99.00,
      'features': ['Complete protection', 'Real-time alerts', 'Bank Verification', 'Priority Support'],
    },
  ];

  final PageController _pageController = PageController(viewportFraction: 0.88);

  bool get hasActiveSub => _activeSub != null && _activeSub!['status'] == 'ACTIVE';

  String get _expiryText {
    if (_activeSub == null) return '';
    try {
      final expiry = DateTime.parse(_activeSub!['expiresAt'].toString());
      final dateStr = '${expiry.day}/${expiry.month}/${expiry.year}';
      return AppLocalizations.of(context)!.subRenewsOn(dateStr);
    } catch (_) {
      return AppLocalizations.of(context)!.subActive;
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await Future.wait([_loadPlans(), _loadActiveSubscription()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPlans() async {
    try {
      final res = await _api.getPlans();
      if (!mounted) return;
      if (res.isNotEmpty) {
        setState(() => _plans = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      log('Error loading plans: $e');
    }
  }

  Future<void> _loadActiveSubscription() async {
    try {
      final res = await _api.getMySubscription();
      if (!mounted) return;
      setState(() => _activeSub = res);
    } catch (e) {
      if (mounted) setState(() => _activeSub = null);
    }
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    if (plan['price'] == 0) return;
    setState(() => _isSubscribing = true);
    try {
      final duration = _isYearly ? const Duration(days: 365) : const Duration(days: 30);
      await _api.createSubscription(
        planId: plan['id'],
        expiresAt: DateTime.now().add(duration),
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, AppLocalizations.of(context)!.subWelcomePremium);
      await _loadActiveSubscription();
    } catch (e) {
      log('Error subscribing: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to activate: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScreenScaffold(
      title: l10n.accountSubscriptionPlan,
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.colors.accentGreen.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? AppLoadingIndicator.center(color: DesignTokens.colors.accentGreen)
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 120),
                          child: hasActiveSub
                              ? _buildSubscriberView()
                              : _buildFreeUserView(),
                        ),
                      ),
                    ],
                  ),
          ),
          if (!_loading && !hasActiveSub)
            Positioned(
              bottom: 24, left: 20, right: 20,
              child: _buildStickyButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = DesignTokens.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl, vertical: DesignTokens.spacing.sm),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacing.sm),
                decoration: BoxDecoration(
                  color: colors.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.shield, color: colors.backgroundDark, size: 24),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FraudShield',
                    style: DesignTypography.h2),
                  Text('PREMIUM',
                    style: DesignTypography.bodyXs.copyWith(
                      color: colors.accentGreen, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.subHeaderNextGen,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textLight.withValues(alpha: 0.55), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeUserView() {
    return Column(
      children: [
        SizedBox(height: 20),
        _buildToggle(),
        SizedBox(height: 28),
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _plans.length,
            itemBuilder: (_, i) => _buildPlanCard(_plans[i]),
          ),
        ),
        SizedBox(height: 36),
        _buildFeatureComparison(),
      ],
    );
  }

  Widget _buildSubscriberView() {
    final colors = DesignTokens.colors;
    return Column(
      children: [
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacing.xxl),
            decoration: BoxDecoration(
              color: colors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
              border: Border.all(color: colors.accentGreen.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacing.lg),
                  decoration: BoxDecoration(
                    color: colors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.badgeCheck, color: colors.accentGreen, size: 44),
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.subPremiumMember,
                  style: DesignTypography.h3,
                ),
                SizedBox(height: 6),
                Text(
                  _expiryText,
                  style: TextStyle(color: colors.textLight.withValues(alpha: 0.55), fontSize: 13),
                ),
                SizedBox(height: 20),
                AppDivider(),
                SizedBox(height: 16),
                ...([
                  'AI Real-time SMS Blocking',
                  'Bank Account Verification',
                  'Priority Threat Insights',
                  '24/7 Priority Support',
                ].map((f) => Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: colors.accentGreen, size: 18),
                      SizedBox(width: 10),
                      Text(f, style: TextStyle(color: colors.textLight.withValues(alpha: 0.75), fontSize: 14)),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacing.xl),
            decoration: BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.textLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                  ),
                  child: Icon(Icons.settings_outlined, color: colors.textLight.withValues(alpha: 0.7), size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.subManageSubscription, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(AppLocalizations.of(context)!.subCancelModify, style: TextStyle(color: colors.textLight.withValues(alpha: 0.45), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textLight.withValues(alpha: 0.38)),
              ],
            ),
          ),
        ),
        SizedBox(height: 32),
        _buildFeatureComparison(showActivePlan: true),
      ],
    );
  }

  Widget _buildToggle() {
    final colors = DesignTokens.colors;
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing.xs),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.textLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(AppLocalizations.of(context)!.subMonthly, !_isYearly),
          _toggleBtn(AppLocalizations.of(context)!.subYearly, _isYearly, hasBadge: true),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool isActive, {bool hasBadge = false}) {
    final colors = DesignTokens.colors;
    return GestureDetector(
      onTap: () => setState(() => _isYearly = text == 'Yearly'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? DesignTokens.colors.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isActive ? colors.textDark : colors.textLight,
                fontWeight: FontWeight.bold, fontSize: 14,
              ),
            ),
            if (hasBadge && !isActive) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: colors.accentGreen, borderRadius: BorderRadius.circular(DesignTokens.radii.xs)),
                child: Text(AppLocalizations.of(context)!.subSave20, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final colors = DesignTokens.colors;
    final bool isPremium = (plan['price'] as num) > 0;
    final bool isCurrent = hasActiveSub && _activeSub!['planId'] == plan['id'];
    double monthlyPrice = (plan['price'] as num).toDouble();
    double? yearlyTotal;
    if (_isYearly && isPremium) {
      yearlyTotal = (plan['priceYearly'] as num?)?.toDouble() ?? (monthlyPrice * 12 * 0.8);
      monthlyPrice = yearlyTotal / 12;
    }
    final priceStr = isPremium ? 'RM ${monthlyPrice.toStringAsFixed(2)}' : 'RM 0';
    final billingText = _isYearly && isPremium
        ? AppLocalizations.of(context)!.subBilledYearly(yearlyTotal!.toStringAsFixed(2))
        : AppLocalizations.of(context)!.subBilledMonthly;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.sm, vertical: DesignTokens.spacing.sm),
      padding: EdgeInsets.all(DesignTokens.spacing.xxl),
      decoration: BoxDecoration(
        color: Color(0xFF162032),
        borderRadius: BorderRadius.circular(DesignTokens.radii.xxl),
        border: isPremium
            ? Border.all(color: colors.accentGreen.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: colors.textLight.withValues(alpha: 0.06)),
        gradient: isPremium
            ? LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [DesignTokens.colors.accentGreen.withValues(alpha: 0.07), Colors.transparent])
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                  plan['name'].toString().toUpperCase(),
                  style: TextStyle(
                    color: isPremium ? colors.accentGreen : colors.textLight.withValues(alpha: 0.54),
                    fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                ),
                if (isPremium)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.sm, vertical: DesignTokens.spacing.xs),
                    decoration: BoxDecoration(
                      color: DesignTokens.colors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                    ),
                    child: Text(AppLocalizations.of(context)!.subPopular, style: TextStyle(color: DesignTokens.colors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
            ],
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: priceStr,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colors.textLight, height: 1.0),
                ),
                TextSpan(
                  text: isPremium ? '/mo' : '',
                  style: TextStyle(color: colors.textLight.withValues(alpha: 0.4), fontSize: 16),
                ),
              ],
            ),
          ),
          if (isPremium) ...[
            SizedBox(height: 4),
            Text(billingText, style: TextStyle(color: colors.textLight.withValues(alpha: 0.4), fontSize: 12)),
          ],
          SizedBox(height: 12),
          Text(
            isPremium
                ? AppLocalizations.of(context)!.subPremiumDescShort
                : AppLocalizations.of(context)!.subBasicDescShort,
            style: TextStyle(color: colors.textLight.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
          ),
          Spacer(),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? AppButton(
                    onPressed: null,
                    label: AppLocalizations.of(context)!.subCurrentPlan,
                    variant: AppButtonVariant.ghost,
                  )
                : AppButton(
                    onPressed: isPremium ? () => _subscribe(plan) : null,
                    label: isPremium ? AppLocalizations.of(context)!.subGetPremium : AppLocalizations.of(context)!.subCurrentPlan,
                    variant: isPremium ? AppButtonVariant.primary : AppButtonVariant.secondary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison({bool showActivePlan = false}) {
    final colors = DesignTokens.colors;
    final features = [
      _Feature('Community Reports', true, true),
      _Feature('AI Real-time SMS Blocking', true, true),
      _Feature('Bank Account Verification', false, true),
      _Feature('Priority Threat Insights', false, true),
      _Feature('QR Code Scan History', false, true),
      _Feature('24/7 Priority Support', false, true),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.subFeatureComparison,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SizedBox()),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(AppLocalizations.of(context)!.subFree, style: TextStyle(color: colors.textLight.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(AppLocalizations.of(context)!.accountPremium, style: TextStyle(color: colors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          AppDivider(),
          SizedBox(height: 4),
          ...features.map((f) => _featureRow(f.label, f.basic, f.premium, showActivePlan: showActivePlan)),
        ],
      ),
    );
  }

  Widget _featureRow(String label, bool basic, bool premium, {bool showActivePlan = false}) {
    final colors = DesignTokens.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
              style: TextStyle(color: colors.textLight.withValues(alpha: 0.75), fontSize: 14)),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _checkIcon(basic, isPremium: false),
                _checkIcon(premium, isPremium: true, isHighlighted: showActivePlan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon(bool enabled, {bool isPremium = false, bool isHighlighted = false}) {
    final colors = DesignTokens.colors;
    if (!enabled) return Container(width: 20, height: 2, color: colors.textLight.withValues(alpha: 0.15));
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isPremium || isHighlighted) ? DesignTokens.colors.accentGreen : Colors.transparent,
      ),
      child: Icon(Icons.check,
          size: 14,
          color: (isPremium || isHighlighted) ? colors.textDark : colors.textLight.withValues(alpha: 0.54)),
    );
  }

  Widget _buildStickyButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: DesignTokens.shadows.md,
      ),
      child: AppButton(
        isLoading: _isSubscribing,
        onPressed: () {
          final premium = _plans.firstWhere((p) => (p['price'] as num) > 0, orElse: () => {});
          if (premium.isNotEmpty) _subscribe(premium);
        },
        label: AppLocalizations.of(context)!.subUpgradeToPremium,
        icon: Icons.arrow_forward_rounded,
        width: double.infinity,
      ),
    );
  }
}

class _Feature {
  final String label;
  final bool basic;
  final bool premium;
  const _Feature(this.label, this.basic, this.premium);
}

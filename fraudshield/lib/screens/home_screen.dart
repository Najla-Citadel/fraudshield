import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/latest_news_widget.dart';
import 'fraud_check_screen.dart';
import 'phishing_protection_screen.dart';
import 'voice_detection_screen.dart';
import 'qr_detection_screen.dart';
import 'scam_reporting_screen.dart';
import 'scam_alerts_screen.dart';
import 'subscription_screen.dart';
import 'points_screen.dart';
import 'account_screen.dart';
import 'community_feed_screen.dart';
import '../widgets/glass_surface.dart';
// import '../widgets/animated_background.dart';
// import '../widgets/fade_in_list.dart';
import '../widgets/skeleton_loader.dart';
import 'activity_screen.dart';
import '../constants/colors.dart';
import '../widgets/security_score_ring.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/security_report_sheet.dart';
import 'transaction_journal_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/daily_digest_widget.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // Removed _userName and _loadingProfile - we will watch the provider directly


  // Key to refresh PointsScreen from Home
  final GlobalKey<PointsScreenState> _pointsKey = GlobalKey<PointsScreenState>();
  final GlobalKey<LatestNewsWidgetState> _newsKey = GlobalKey<LatestNewsWidgetState>();

  // Customization State
  List<String> _activeQuickActions = ['fraud_check', 'qr_scan', 'report_scam'];

  // Security Center State
  bool _isScanning = false;
  int _securityScore = 85; // Initial placeholder
  String _securityStatus = 'GOOD';
  List<dynamic> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadQuickActions();
    _loadRecentTransactions();
    _fetchSecurityHealth();
    
    // Listen for real-time alerts
    NotificationService.instance.addListener(_handleNewAlert);

    // Check for daily login reward
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
      _checkSecurityGuide();
    });
  }

  Future<void> _checkSecurityGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('score_guide_seen') ?? false;
    
    if (!seen && mounted) {
      await Future.delayed(const Duration(milliseconds: 1500)); // Wait for initial animations
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassSurface(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 64, color: AppColors.accentGreen),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.homeWelcomeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.homeWelcomeDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await prefs.setBool('score_guide_seen', true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.homeWelcomeBtn),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  int _calculateSecurityScore(bool isSubscribed) {
    return _securityScore;
  }

  void _runQuickScan(bool isSubscribed) {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);

    // Simulate system scan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
        _showSecurityReport(isSubscribed);
      }
    });
  }

  void _showSecurityReport(bool isSubscribed) {
    final authProvider = context.read<AuthProvider>();
    final fullName = authProvider.userProfile?.fullName;
    final profileComplete = fullName != null && fullName.trim().isNotEmpty;
    final activeDefenses = _activeQuickActions.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SecurityReportSheet(
        score: _calculateSecurityScore(isSubscribed),
        isSubscribed: isSubscribed,
        profileComplete: profileComplete,
        activeDefensesCount: activeDefenses,
        onFixPremium: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          );
        },
        onUpdateProfile: () {
          Navigator.pop(context);
          _onNavTap(4); // Switch to Account Tab
        },
        onEnableDefenses: () {
          Navigator.pop(context);
          _showCustomizationSheet();
        },
      ),
    );
  }

  Future<void> _fetchSecurityHealth() async {
    try {
      final health = await ApiService.instance.getSecurityHealth();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _securityScore = health['score'];
          final score = _securityScore;
          if (score >= 90) _securityStatus = l10n.statusExcellent;
          else if (score >= 75) _securityStatus = l10n.statusGood;
          else if (score >= 50) _securityStatus = l10n.statusProtected;
          else _securityStatus = l10n.statusAtRisk;
        });
      }
    } catch (e) {
      debugPrint('Error fetching security health: $e');
    }
  }

  Future<void> _saveQuickActions(List<String> actions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('active_quick_actions', actions);
    setState(() {
      _activeQuickActions = actions;
    });
  }

  void _handleNewAlert() {
    if (!mounted) return;
    final alerts = NotificationService.instance.alerts;
    if (alerts.isNotEmpty) {
      final latest = alerts.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(latest['title'] ?? 'Fraud Warning', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(latest['message'] ?? 'Suspicious activity detected'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'VIEW', textColor: Colors.white, onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScamAlertsScreen()),
            );
          }),
        ),
      );
    }
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_handleNewAlert);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = context.read<AuthProvider>();
    
    // Trigger profile fetch if not already present
    if (authProvider.userProfile == null) {
      try {
        await authProvider.refreshProfile();
      } catch (e) {
        debugPrint('HomeScreen: Error loading profile: $e');
      }
    }
  }

  Future<void> _checkDailyReward() async {
    try {
      final res = await ApiService.instance.claimDailyReward();
      if (res['claimed'] == true && mounted) {
        // Refresh profile to update points in UI
        context.read<AuthProvider>().refreshProfile();
        // Also refresh points screen if it's cached
        _pointsKey.currentState?.refreshData();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _DailyRewardDialog(
            points: res['points'] ?? 0,
            streak: res['streak'] ?? 1,
            message: res['message'] ?? 'Thanks for being part of the community!',
            nextReward: res['nextReward'] ?? 20,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking daily reward: $e');
    }
  }

  Future<void> _loadQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('active_quick_actions');
    if (saved != null) {
      setState(() {
        _activeQuickActions = saved;
      });
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final data = await ApiService.instance.getTransactionJournal(limit: 3);
      if (mounted) {
        setState(() {
          _recentTransactions = data['results'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load recent transactions on Home: $e');
    }
  }

  void _showCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Local state for the sheet
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select which actions to display on your dashboard.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Toggles
                  _buildToggleItem(
                    'Fraud Check',
                    'Scan QR or check ID',
                    _activeQuickActions.contains('fraud_check'),
                    (val) {
                      setSheetState(() {
                        if (val) {
                          _activeQuickActions.add('fraud_check');
                        } else {
                          _activeQuickActions.remove('fraud_check');
                        }
                      });
                      _saveQuickActions(_activeQuickActions); // Save immediately
                    },
                  ),
                  _buildToggleItem(
                    'QR Scan',
                    'Scan any QR code safely',
                    _activeQuickActions.contains('qr_scan'),
                    (val) {
                      setSheetState(() {
                        if (val) {
                          _activeQuickActions.add('qr_scan');
                        } else {
                          _activeQuickActions.remove('qr_scan');
                        }
                      });
                      _saveQuickActions(_activeQuickActions);
                    },
                  ),
                  _buildToggleItem(
                    'Report Scam',
                    'Report a number or a website',
                    _activeQuickActions.contains('report_scam'),
                    (val) {
                      setSheetState(() {
                        if (val) {
                          _activeQuickActions.add('report_scam');
                        } else {
                          _activeQuickActions.remove('report_scam');
                        }
                      });
                      _saveQuickActions(_activeQuickActions);
                    },
                  ),
                  _buildToggleItem(
                    'Voice Detection',
                    'Analyze calls in real-time',
                    _activeQuickActions.contains('voice_detection'),
                    (val) {
                      setSheetState(() {
                        if (val) {
                          _activeQuickActions.add('voice_detection');
                        } else {
                          _activeQuickActions.remove('voice_detection');
                        }
                      });
                      _saveQuickActions(_activeQuickActions);
                    },
                  ),
                  _buildToggleItem(
                    'Phishing Protection',
                    'Check links and messages',
                    _activeQuickActions.contains('phishing_protection'),
                    (val) {
                      setSheetState(() {
                        if (val) {
                          _activeQuickActions.add('phishing_protection');
                        } else {
                          _activeQuickActions.remove('phishing_protection');
                        }
                      });
                      _saveQuickActions(_activeQuickActions);
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassSurface( // Reusing GlassSurface for consistent look
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accentGreen,
              activeTrackColor: AppColors.accentGreen.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadProfile(),
      _loadQuickActions(),
      _loadRecentTransactions(),
      _fetchSecurityHealth(),
    ]);
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _loadProfile(); // refresh greeting
    }

    // Refresh Points tab when tapped
    if (index == 3) {
      _pointsKey.currentState?.refreshData();
    }
  }



// ... inside HomeScreen build method ...

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isSubscribed = authProvider.isSubscribed;
    final loading = authProvider.loading;
    
    String? name = authProvider.userProfile?.fullName;
    if (name != null && name.trim().isEmpty) {
      name = null;
    }
    final displayUserName = name ?? 
                           authProvider.user?.email?.split('@').first ?? 
                           'User';

    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating nav bar
      backgroundColor: AppColors.deepNavy,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            userName: displayUserName,
            loading: loading,
            activeQuickActions: _activeQuickActions,
            onCustomize: () => _showCustomizationSheet(),
            isSubscribed: isSubscribed,
            isScanning: _isScanning,
            score: _calculateSecurityScore(isSubscribed),
            status: _securityStatus,
            onScan: () => _runQuickScan(isSubscribed),
            onShowReport: () => _showSecurityReport(isSubscribed),
            recentTransactions: _recentTransactions,
            newsKey: _newsKey,
            onRefresh: _handleRefresh,
          ),
          const CommunityFeedScreen(),
          const ActivityScreen(),
          PointsScreen(key: _pointsKey),
          const AccountScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  final bool loading;
  final List<String> activeQuickActions;
  final VoidCallback onCustomize;
  final bool isSubscribed;
  
  // New props for security center
  final bool isScanning;
  final int score;
  final String status;
  final VoidCallback onScan;
  final VoidCallback onShowReport;
  final List<dynamic> recentTransactions;
  final GlobalKey<LatestNewsWidgetState> newsKey;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.userName,
    required this.loading,
    required this.activeQuickActions,
    required this.onCustomize,
    required this.isSubscribed,
    required this.isScanning,
    required this.score,
    required this.status,
    required this.onScan,
    required this.onShowReport,
    required this.recentTransactions,
    required this.newsKey,
    required this.onRefresh,
  });

  String _getDynamicGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.homeGreetingMorning;
    } else if (hour < 17) {
      return l10n.homeGreetingAfternoon;
    }
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire HomeTab in AnimatedBackground for that premium feel
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNavy, // Force Deep Navy background for this tab
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.accentGreen,
          backgroundColor: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100), // Extra bottom padding for nav bar
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDynamicGreeting(context),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      loading
                          ? const SkeletonLoader(width: 100, height: 24, borderRadius: 4)
                          : Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2, // Fixed: height, not maxHeight
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ScamAlertsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 2. SECURITY SCORE RING (Interactive)
              GestureDetector(
                onTap: () {
                  if (!isScanning) onScan();
                },
                child: SecurityScoreRing(
                  score: score,
                  status: status,
                  isScanning: isScanning,
                  onTap: onScan,
                  onInfoTap: onShowReport,
                ),
              ),

              const SizedBox(height: 16),
              _buildMonitoringPill(),
              const SizedBox(height: 24),

              // 3. SERVICES ROW
              _buildQuickActions(context),

              const SizedBox(height: 24),

              // 4. TRENDING ALERTS CARD
              _buildTrendingAlertsCard(context),

              const SizedBox(height: 24),

              // 5. DAILY INSIGHTS
              const DailyDigestWidget(),

              const SizedBox(height: 24),

              // 6. PAYMENT JOURNAL CARD
              _buildPaymentJournalCard(context),

              const SizedBox(height: 32),

              // NEW: RECENT CHECKS (formerly SECURITY JOURNAL)
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.homeRecentChecks,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionJournalScreen()),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.homeViewAll,
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                       Icon(LucideIcons.shieldCheck, color: Colors.grey.withValues(alpha: 0.5), size: 32),
                       const SizedBox(height: 8),
                       Text(AppLocalizations.of(context)!.homeNoRecentScans, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...recentTransactions.map((tx) {
                   final type = tx['checkType'] ?? 'UNKNOWN';
                   final target = tx['target'] ?? '';
                   final status = tx['status'] ?? 'SAFE';
                   
                   IconData icon;
                   switch (type) {
                     case 'URL': icon = LucideIcons.link; break;
                     case 'PHONE': icon = LucideIcons.phone; break;
                     case 'BANK': icon = LucideIcons.building; break;
                     default: icon = LucideIcons.fileText;
                   }

                   Color color;
                   if (status == 'SAFE') color = AppColors.accentGreen;
                   else if (status == 'SUSPICIOUS') color = Colors.orangeAccent;
                   else color = Colors.redAccent;

                   return Container(
                     margin: const EdgeInsets.only(bottom: 8),
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFF1E293B),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: color.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: Icon(icon, color: color, size: 16),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(target, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                               Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                             ],
                           ),
                         ),
                       ],
                     ),
                   );
                }),

              const SizedBox(height: 32),

              // Redundant services list removed

              // 7. THREAT INSIGHTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.homeThreatInsights,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => newsKey.currentState?.showCustomization(),
                    child: const Icon(Icons.tune, color: Colors.blueAccent, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LatestNewsWidget(key: newsKey),

              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.homeServices,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: onCustomize,
              child: const Icon(Icons.tune, color: Colors.blueAccent, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activeQuickActions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.grey, size: 30),
                const SizedBox(height: 8),
                Text(
                  'Add Services',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          )
        else
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                stops: const [0.9, 1.0], // Fade out the last 10%
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Add slight right padding to ensure the last item can be scrolled away from the edge manually if needed, 
              // but mostly rely on the fading mask for the visual cue.
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (activeQuickActions.contains('fraud_check'))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BigActionButton(
                        label: 'Fraud Check',
                        icon: Icons.health_and_safety,
                        color: const Color(0xFF3B82F6), // Blue
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FraudCheckScreen()),
                        ),
                      ),
                    ),
                  if (activeQuickActions.contains('qr_scan'))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BigActionButton(
                        label: 'QR Scan',
                        icon: Icons.qr_code_scanner,
                        color: const Color(0xFF1E293B), // Dark Button
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QRDetectionScreen()),
                        ),
                      ),
                    ),
                  if (activeQuickActions.contains('report_scam'))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BigActionButton(
                        label: 'Report',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFF1E293B), // Dark Button
                        isAlert: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScamReportingScreen()),
                        ),
                      ),
                    ),
                  if (activeQuickActions.contains('voice_detection'))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BigActionButton(
                        label: AppLocalizations.of(context)!.homeVoiceCheck,
                        icon: Icons.mic,
                        color: const Color(0xFF1E293B),
                        isLocked: !isSubscribed,
                        onTap: () {
                          if (isSubscribed) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VoiceDetectionScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.homeUnlockVoice),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context)!.homeUpgrade,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  if (activeQuickActions.contains('phishing_protection'))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BigActionButton(
                        label: AppLocalizations.of(context)!.homePhishing,
                        icon: Icons.shield,
                        color: const Color(0xFF1E293B),
                        isLocked: !isSubscribed,
                        onTap: () {
                          if (isSubscribed) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PhishingProtectionScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.homeUnlockPhishing),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context)!.homeUpgrade,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendingAlertsCard(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (context, child) {
        final alerts = NotificationService.instance.alerts;
        final hasAlerts = alerts.isNotEmpty;
        final latestAlert = hasAlerts ? alerts.first : null;

        final isWarning = hasAlerts && (latestAlert!['severity'] == 'high' || latestAlert['severity'] == 'critical');
        final iconColor = hasAlerts 
            ? (isWarning ? Colors.redAccent : Colors.orangeAccent)
            : AppColors.accentGreen;
            
        final iconData = hasAlerts ? LucideIcons.alertTriangle : LucideIcons.shieldCheck;
        final title = hasAlerts 
            ? (latestAlert!['title'] ?? AppLocalizations.of(context)!.homeTrendingThreats)
            : 'No Active Threats';
            
        final subtitle = hasAlerts 
            ? (latestAlert!['message'] ?? AppLocalizations.of(context)!.homeTrendingDesc)
            : 'Your security environment is currently clear and protected.';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScamAlertsScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasAlerts ? iconColor.withValues(alpha: 0.3) : Colors.transparent,
                width: 1,
              ),
              boxShadow: hasAlerts ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.5), size: 14),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonitoringPill() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Dark Slate
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.3 * value),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGreen.withValues(alpha: 0.1 * value),
                blurRadius: 8 * value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: AppColors.accentGreen.withValues(alpha: value),
                size: 8,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.homeSystemActive,
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      onEnd: () {}, 
    );
  }

  Widget _buildPaymentJournalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Match trending alerts style
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.accentGreen, size: 24),
              const SizedBox(width: 10),
              const Text(
                'PAYMENT JOURNAL',
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Unsure about a seller? Log the payment here before you transfer money.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.4),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionJournalScreen()),
                );
              },
              icon: const Text('Log Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              label: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// WIDGETS
////////////////////////////////////////////////////////////////

class _BigActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isAlert;
  final bool isLocked;

  const _BigActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isAlert = false,
    this.isLocked = false,
  });

  @override
  State<_BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<_BigActionButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 100, // Fixed width for uniformity
            height: 115, // Increased height to prevent overflow
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced horizontal padding
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _isPressed ? 0.05 : 0.2),
                  blurRadius: _isPressed ? 4 : 12,
                  offset: Offset(0, _isPressed ? 2 : 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 32,
                      color: widget.isAlert ? Colors.orange : Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible, // Allow wrapping
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Slightly smaller font
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                if (widget.isLocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.lock, size: 16, color: Colors.white.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isLocked;

  const _StatusItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: onTap != null ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.5), size: 20),
              )
            else if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.5), blurRadius: 6)
                  ],
                ),
              )
            else if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _DailyRewardDialog extends StatelessWidget {
  final int points;
  final int streak;
  final String message;
  final int nextReward;

  const _DailyRewardDialog({
    required this.points,
    required this.streak,
    required this.message,
    required this.nextReward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: GlassSurface(
        borderRadius: 20,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 Daily Bonus!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.stars, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '+$points Points',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Streak: $streak Days',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tomorrow\'s Reward: $nextReward Points',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Awesome!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'awareness_tips_screen.dart';
import 'subscription_screen.dart';
import 'points_screen.dart';
import 'account_screen.dart';
import 'community_feed_screen.dart';
import '../widgets/glass_surface.dart';
// import '../widgets/animated_background.dart';
import '../widgets/fade_slide_route.dart';
// import '../widgets/fade_in_list.dart';
import '../widgets/skeleton_loader.dart';
import 'activity_screen.dart';
import '../constants/colors.dart';
import '../widgets/security_score_ring.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/security_report_sheet.dart';
import 'transaction_journal_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User';
  bool _loadingProfile = true;

  // Key to refresh PointsScreen from Home
  final GlobalKey<PointsScreenState> _pointsKey = GlobalKey<PointsScreenState>();

  // Customization State
  List<String> _activeQuickActions = ['fraud_check', 'qr_scan', 'report_scam'];

  // Security Center State
  bool _isScanning = false;
  List<dynamic> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadQuickActions();
    _loadRecentTransactions();
    
    // Listen for real-time alerts
    NotificationService.instance.addListener(_handleNewAlert);

    // Check for daily login reward
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  int _calculateSecurityScore(bool isSubscribed) {
    int score = 70; // Base score
    if (isSubscribed) score += 15;
    if (_userName != 'User') score += 5; // Profile set
    // Future: Check permissions
    if (_activeQuickActions.isNotEmpty) score += 5;
    return score;
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
    final profileComplete = _userName != 'User';
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
    
    // AuthProvider already handles profile loading/refreshing
    if (authProvider.userProfile == null) {
      await authProvider.refreshProfile();
    }

    if (mounted) {
      setState(() {
        _userName = authProvider.userProfile?.fullName ?? 
                   authProvider.user?.email?.split('@').first ?? 
                   'User';
        _loadingProfile = false;
      });
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
            points: res['points'],
            streak: res['streak'],
            message: res['message'],
            nextReward: res['nextReward'],
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
                    'Customize Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select which actions to display on your dashboard.',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
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
                      color: Colors.white.withOpacity(0.5),
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
              activeTrackColor: AppColors.accentGreen.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
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
    final isSubscribed = context.watch<AuthProvider>().isSubscribed;

    return Scaffold(
      extendBody: true, // Allows content to flow behind the floating nav bar
      backgroundColor: AppColors.deepNavy,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            userName: _userName,
            loading: _loadingProfile,
            activeQuickActions: _activeQuickActions,
            onCustomize: () => _showCustomizationSheet(),
            isSubscribed: isSubscribed,
            // Pass security state down
            isScanning: _isScanning,
            score: _calculateSecurityScore(isSubscribed),
            onScan: () => _runQuickScan(isSubscribed),
            recentTransactions: _recentTransactions,
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
  final VoidCallback onScan;
  final List<dynamic> recentTransactions;

  const _HomeTab({
    required this.userName,
    required this.loading,
    required this.activeQuickActions,
    required this.onCustomize,
    required this.isSubscribed,
    required this.isScanning,
    required this.score,
    required this.onScan,
    required this.recentTransactions,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap entire HomeTab in AnimatedBackground for that premium feel
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNavy, // Force Deep Navy background for this tab
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
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
                        'Good Evening,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
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
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.accentGreen,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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
                  status: score >= 90 ? 'Excellent' : 'Good',
                  isScanning: isScanning,
                  onTap: onScan,
                ),
              ),

              const SizedBox(height: 30),

              // 3. MONITORING PILL (Animated)
              _buildMonitoringPill(),

              // 4. QUICK ACTIONS ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.grey, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        'Add Quick Actions',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                          label: 'Voice Check',
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
                                    content: const Text('Subscribe to unlock Voice Check!'),
                                    action: SnackBarAction(
                                      label: 'UPGRADE',
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
                          label: 'Phishing',
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
                                    content: const Text('Subscribe to unlock Phishing Protection!'),
                                    action: SnackBarAction(
                                      label: 'UPGRADE',
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

              const SizedBox(height: 32),

              // NEW: TRENDING ALERTS CARD
              _buildTrendingAlertsCard(context),

              const SizedBox(height: 32),

              // NEW: SECURITY JOURNAL
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SECURITY JOURNAL',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
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
                        'View All',
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
                       Icon(LucideIcons.shieldCheck, color: Colors.grey.withOpacity(0.5), size: 32),
                       const SizedBox(height: 8),
                       Text('No recent scans recorded.', style: TextStyle(color: Colors.grey)),
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
                             color: color.withOpacity(0.1),
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

              // 5. ALL SERVICES (Renamed from PROTECTION STATUS)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ALL SERVICES',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _StatusItem(
                icon: Icons.health_and_safety,
                title: 'Fraud Check',
                subtitle: 'Scan QR or check ID',
                isActive: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FraudCheckScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _StatusItem(
                icon: Icons.qr_code_scanner,
                title: 'QR Scan',
                subtitle: 'Scan any QR code safely',
                isActive: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRDetectionScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _StatusItem(
                icon: Icons.warning_amber_rounded,
                title: 'Report Scam',
                subtitle: 'Report a number or a website',
                isActive: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScamReportingScreen()),
                ),
              ),

              const SizedBox(height: 32),

              // 6. PRO SERVICES
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'PRO SERVICES',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                      ),
                      child: const Text('PREMIUM', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _StatusItem(
                icon: Icons.mic,
                title: 'Voice Detection',
                subtitle: 'Analyze suspicious calls in real-time',
                isActive: isSubscribed,
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
                        content: const Text('Subscribe to unlock Voice Detection!'),
                        action: SnackBarAction(
                          label: 'UPGRADE',
                          onPressed: () {
                            // Navigate to subscription screen
                            // Since we are in HomeTab, we might need a way to switch tabs or push screen
                            // For now, simpler to push SubscriptionScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _StatusItem(
                icon: Icons.shield,
                title: 'Phishing Protection',
                subtitle: 'Check links and messages safety',
                isActive: isSubscribed,
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
                        content: const Text('Subscribe to unlock Phishing Protection!'),
                        action: SnackBarAction(
                          label: 'UPGRADE',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // 7. THREAT INSIGHTS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'THREAT INSIGHTS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const LatestNewsWidget(),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingAlertsCard(BuildContext context) {
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
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.05),
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
                const Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'TRENDING THREATS',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 14),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Stay ahead of the latest scams in your area. Check the threat intelligence dashboard now.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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
              color: AppColors.accentGreen.withOpacity(0.3 * value),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGreen.withOpacity(0.1 * value),
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
                color: AppColors.accentGreen.withOpacity(value),
                size: 8,
              ),
              const SizedBox(width: 8),
              const Text(
                'System Shield Active',
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
}

////////////////////////////////////////////////////////////////
/// WIDGETS
////////////////////////////////////////////////////////////////

class _BigActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Fixed width for uniformity
        height: 115, // Increased height to prevent overflow
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  icon,
                  size: 32,
                  color: isAlert ? Colors.orange : Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  label,
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
            if (isLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.lock, size: 16, color: Colors.white.withOpacity(0.7)),
              ),
          ],
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
          border: onTap != null ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
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
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.lock, color: Colors.white.withOpacity(0.5), size: 20),
              )
            else if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(color: AppColors.accentGreen.withOpacity(0.5), blurRadius: 6)
                  ],
                ),
              )
            else if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white.withOpacity(0.3)),
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

import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glass_surface.dart';
import '../widgets/animated_background.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
=======
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
>>>>>>> dev-ui2

class PhishingProtectionScreen extends StatefulWidget {
  const PhishingProtectionScreen({super.key});

  @override
  State<PhishingProtectionScreen> createState() => _PhishingProtectionScreenState();
}

class _PhishingProtectionScreenState extends State<PhishingProtectionScreen> {
<<<<<<< HEAD
  bool isProtected = true; // Mock safe/unsafe toggle

  final List<Map<String, dynamic>> recentActivities = [
    {
      'url': 'www.bank-secure-update.com',
      'status': 'Suspicious',
      'date': '03 Nov 2025',
    },
    {
      'url': 'www.maybank2u.com.my',
      'status': 'Safe',
      'date': '02 Nov 2025',
    },
    {
      'url': 'sms: +60123456789',
      'status': 'Suspicious',
      'date': '01 Nov 2025',
    },
    {
      'url': 'www.lazada.com.my',
      'status': 'Safe',
      'date': '30 Oct 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBackground(
      child: AdaptiveScaffold(
        title: 'Phishing Protection',
        backgroundColor: Colors.transparent, // Allow animated background to show
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🛡️ Header Section
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stay protected from fake websites, messages, and scams.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
  
              // 🟢 Status Card
              GlassSurface(
                accentColor: isProtected ? Colors.green : theme.colorScheme.error,
                child: Column(
                  children: [
                    Icon(
                      isProtected ? Icons.verified_user : Icons.warning_rounded,
                      color: isProtected ? Colors.green : theme.colorScheme.error,
                      size: 70,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isProtected ? 'You are Safe' : 'Suspicious Activity Detected!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isProtected ? Colors.green[800] : theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isProtected
                          ? 'No phishing threat found recently.'
                          : 'Some phishing URLs were detected recently.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AdaptiveButton(
                      onPressed: () {
                        setState(() {
                          isProtected = !isProtected;
                        });
                      },
                      text: isProtected ? 'Simulate Threat' : 'Back to Safe Mode',
                      // Optional: Make button style variant for threat mode?
                    ),
                  ],
                ),
              ),
  
              const SizedBox(height: 40),
  
              // 🕓 Recent Activity
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
  
              // 🧾 List of recent scans
              GlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: AnimationLimiter(
                  child: Column(
                    children: recentActivities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSuspicious = item['status'] == 'Suspicious';
                      
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Icon(
                                    isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle,
                                    color: isSuspicious ? theme.colorScheme.error : Colors.green,
                                  ),
                                  title: Text(
                                    item['url'],
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    item['date'],
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSuspicious ? theme.colorScheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSuspicious ? theme.colorScheme.error.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      item['status'],
                                      style: TextStyle(
                                        color: isSuspicious ? theme.colorScheme.error : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index != recentActivities.length - 1)
                                  Divider(
                                    indent: 20, 
                                    endIndent: 20, 
                                    height: 1, 
                                    color: theme.colorScheme.outline.withOpacity(0.5)
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
=======
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _lastResult;
  List<dynamic> _recentScans = [];
  bool _isFetchingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await ApiService.instance.getTransactionJournal(type: 'URL');
      if (mounted) {
        setState(() {
          _recentScans = response['results'] ?? [];
          _isFetchingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching URL history: $e');
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  Future<void> _checkUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.instance.checkUrl(url);
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isLoading = false;
        });
        // Refresh history after check
        _fetchHistory();
      }
    } catch (e) {
      debugPrint('Error checking URL: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check URL: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'URL Link Check',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(height: 24),
            if (_lastResult != null) ...[
              _buildResultCard(),
              const SizedBox(height: 32),
            ],
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
            const SizedBox(height: 100), // Spacing for floating nav bar if needed
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.globe, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Enter URL to scan',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              filled: true,
              fillColor: AppColors.lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Check Link',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isSafe = _lastResult?['safe'] ?? false;
    final url = _lastResult?['url'] ?? '';
    final threats = (_lastResult?['threats'] as List?)?.join(', ') ?? 'None';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isSafe ? AppColors.accentGreen.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSafe ? AppColors.accentGreen.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
            color: isSafe ? AppColors.accentGreen : Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isSafe ? 'Website is Safe' : 'Suspicious Website',
            style: TextStyle(
              color: isSafe ? AppColors.accentGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            url,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isSafe) ...[
            const SizedBox(height: 12),
            Text(
              'Threats detected: $threats',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_isFetchingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentScans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.history, color: AppColors.greyText.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            const Text(
              'No recent activity',
              style: TextStyle(color: AppColors.greyText),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentScans.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.lightBg),
        itemBuilder: (context, index) {
          final scan = _recentScans[index];
          final isSafe = scan['status'] == 'SAFE';
          final DateTime date = DateTime.parse(scan['createdAt']);
          final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: isSafe ? AppColors.accentGreen : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              scan['target'] ?? 'Unknown URL',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              formattedDate,
              style: const TextStyle(color: AppColors.greyText, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isSafe ? 'SAFE' : 'RISKY',
                style: TextStyle(
                  color: isSafe ? AppColors.accentGreen : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          );
        },
>>>>>>> dev-ui2
      ),
    );
  }
}

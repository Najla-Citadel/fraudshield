import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/risk_evaluator.dart';
import '../widgets/glass_surface.dart';
import '../widgets/security_tips_card.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UrlLinkCheckScreen extends StatefulWidget {
  const UrlLinkCheckScreen({super.key});

  @override
  State<UrlLinkCheckScreen> createState() => _UrlLinkCheckScreenState();
}

class _UrlLinkCheckScreenState extends State<UrlLinkCheckScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  RiskResult? _lastResult;
  List<dynamic> _recentScans = [];
  bool _isFetchingHistory = true;
  DateTime? _lastClearedAt;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() => setState(() {}));
    _loadClearedTimestamp().then((_) => _fetchHistory());
  }

  Future<void> _loadClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('url_history_cleared_at');
    if (ts != null) {
      if (mounted) setState(() => _lastClearedAt = DateTime.parse(ts));
    }
  }

  Future<void> _saveClearedTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('url_history_cleared_at', now.toIso8601String());
    if (mounted) setState(() => _lastClearedAt = now);
  }

  Future<void> _fetchHistory() async {
    try {
      final response =
          await ApiService.instance.getTransactionJournal(type: 'URL');
      if (mounted) {
        setState(() {
          List<dynamic> results = response['results'] ?? [];
          // Filter out scans before _lastClearedAt
          if (_lastClearedAt != null) {
            results = results.where((scan) {
              final scanDate = DateTime.parse(scan['createdAt']);
              return scanDate.isAfter(_lastClearedAt!);
            }).toList();
          }
          _recentScans = results;
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
      final result = await RiskEvaluator.evaluateUrl(url);
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            AppColors.deepNavy,
            Color(0xFF1E3A8A),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'URL Link Check',
            style: TextStyle(
              color: Colors.white,
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
              const SecurityTipsCard(tips: [
                'Check links from SMS, WhatsApp, or email before opening.',
                'Avoid clicking links that create a false sense of urgency.',
                "Always verify the domain name (e.g., 'google.com' vs 'qooqle.com').",
              ]),
              const SizedBox(height: 24),
              _buildInputSection(),
              const SizedBox(height: 24),
              if (_lastResult != null) ...[
                _buildResultCard(),
                const SizedBox(height: 32),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_recentScans.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _saveClearedTimestamp();
                        setState(() => _recentScans = []);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.4),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child:
                          const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentActivity(),
              const SizedBox(
                  height: 100), // Spacing for floating nav bar if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassSurface(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      accentColor: AppColors.primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.globe, color: AppColors.primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Enter URL to scan',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
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
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: Icon(LucideIcons.link,
                  color: Colors.white.withValues(alpha: 0.3), size: 18),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(LucideIcons.xCircle,
                          color: Colors.white.withValues(alpha: 0.3), size: 18),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 15, color: Colors.white),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_lastResult == null) return const SizedBox.shrink();

    final isSafe = _lastResult!.score < 30;
    final riskColor = _lastResult!.level == 'critical'
        ? Colors.red
        : _lastResult!.level == 'high'
            ? Colors.orange
            : _lastResult!.level == 'medium'
                ? Colors.yellow[700]!
                : AppColors.accentGreen;

    return GlassSurface(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      borderColor: riskColor.withValues(alpha: 0.3),
      accentColor: AppColors.primaryBlue,
      child: Column(
        children: [
          Icon(
            isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
            color: riskColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isSafe ? 'Website is Safe' : 'Suspicious Website',
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _urlController.text.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Risk Score Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Risk Score: ',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
              Text(
                '${_lastResult!.score}/100',
                style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          if (_lastResult!.reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 8),
            ..._lastResult!.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(LucideIcons.dot, color: riskColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
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
      return GlassSurface(
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        accentColor: AppColors.primaryBlue,
        child: Column(
          children: [
            Icon(LucideIcons.history,
                color: AppColors.greyText.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            const Text(
              'No recent activity',
              style: TextStyle(color: AppColors.greyText),
            ),
          ],
        ),
      );
    }

    return GlassSurface(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      accentColor: AppColors.primaryBlue,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentScans.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final scan = _recentScans[index];
          final isSafe = scan['status'] == 'SAFE';
          final DateTime date = DateTime.parse(scan['createdAt']);
          final String formattedDate =
              DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red)
                    .withValues(alpha: 0.1),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              formattedDate,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isSafe ? AppColors.accentGreen : Colors.red)
                    .withValues(alpha: 0.1),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class PhishingProtectionScreen extends StatefulWidget {
  const PhishingProtectionScreen({super.key});

  @override
  State<PhishingProtectionScreen> createState() => _PhishingProtectionScreenState();
}

class _PhishingProtectionScreenState extends State<PhishingProtectionScreen> {
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
      ),
    );
  }
}

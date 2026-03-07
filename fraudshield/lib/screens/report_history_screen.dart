import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system/tokens/design_tokens.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_back_button.dart';
import '../design_system/components/app_snackbar.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final isInitialLoad = _reports.isEmpty && _errorMessage == null;

    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final reports = await ApiService.instance.getMyReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (isInitialLoad) {
            _errorMessage = e.toString();
          } else {
            AppSnackBar.showError(context, 'Failed to refresh: $e');
          }
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Report History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                color: Colors.white, size: 20),
            onPressed: _fetchReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F172A), // Slate 900
                  DesignTokens.colors.backgroundDark, // Deep navy
                  const Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? ErrorState(
                        onRetry: _fetchReports,
                        message: _errorMessage!,
                      )
                    : _reports.isEmpty
                        ? _buildEmptyState()
                        : _buildReportList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => const SkeletonCard(
        height: 120,
        margin: EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.inbox,
                  size: 64, color: Colors.white.withOpacity(0.2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submitted scam reports will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList() {
    return RefreshIndicator(
      onRefresh: _fetchReports,
      backgroundColor: DesignTokens.colors.backgroundDark,
      color: DesignTokens.colors.accentGreen,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _historyCard(
                    title: '${report['type']} - ${report['category']}',
                    description: report['description'] ?? '',
                    date: _formatDate(report['createdAt']),
                    status: report['status'] ?? 'PENDING',
                    statusColor: _getStatusColor(report['status'] ?? 'PENDING'),
                    isPublic: report['isPublic'] ?? false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _historyCard({
    required String title,
    required String description,
    required String date,
    required String status,
    required Color statusColor,
    required bool isPublic,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.fileText,
                    color: DesignTokens.colors.primary, size: 20),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPublic) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.users,
                    size: 14,
                    color: DesignTokens.colors.accentGreen.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'Shared with community',
                  style: TextStyle(
                      fontSize: 11,
                      color: DesignTokens.colors.accentGreen.withOpacity(0.5),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

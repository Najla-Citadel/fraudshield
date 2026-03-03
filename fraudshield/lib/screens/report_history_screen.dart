import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
<<<<<<< HEAD
=======
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons/lucide_icons.dart';
>>>>>>> dev-ui2

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to refresh: $e')),
            );
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
<<<<<<< HEAD
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
=======
      backgroundColor: AppColors.deepNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
>>>>>>> dev-ui2
        title: const Text(
          'Report History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
<<<<<<< HEAD
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
=======
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                color: Colors.white, size: 20),
>>>>>>> dev-ui2
            onPressed: _fetchReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
<<<<<<< HEAD
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const SkeletonCard(height: 120, margin: EdgeInsets.only(bottom: 12)),
            )
          : _errorMessage != null
              ? ErrorState(
                  onRetry: _fetchReports,
                  message: _errorMessage!,
                )
              : _reports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Reports Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your submitted scam reports will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _historyCard(
                            title: '${report['type']} - ${report['category']}',
                            description: report['description'] ?? '',
                            date: _formatDate(report['createdAt']),
                            status: report['status'] ?? 'PENDING',
                            statusColor: _getStatusColor(report['status'] ?? 'PENDING'),
                            isPublic: report['isPublic'] ?? false,
                          );
                        },
                      ),
                    ),
=======
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  AppColors.deepNavy, // Deep navy
                  Color(0xFF1E3A8A), // Blue 900
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
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
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.inbox,
                  size: 64, color: Colors.white.withValues(alpha: 0.2)),
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList() {
    return RefreshIndicator(
      onRefresh: _fetchReports,
      backgroundColor: AppColors.deepNavy,
      color: AppColors.accentGreen,
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
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
=======
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
>>>>>>> dev-ui2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
<<<<<<< HEAD
              Icon(Icons.report_outlined,
                  color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
=======
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.fileText,
                    color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 16),
>>>>>>> dev-ui2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
<<<<<<< HEAD
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
=======
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
>>>>>>> dev-ui2
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
<<<<<<< HEAD
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
=======
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4)),
>>>>>>> dev-ui2
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
<<<<<<< HEAD
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
=======
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
>>>>>>> dev-ui2
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
<<<<<<< HEAD
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
=======
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5),
              maxLines: 3,
>>>>>>> dev-ui2
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isPublic) ...[
<<<<<<< HEAD
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.public, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Shared with community',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
=======
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(LucideIcons.users,
                    size: 14,
                    color: AppColors.accentGreen.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'Shared with community',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.accentGreen.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500),
>>>>>>> dev-ui2
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

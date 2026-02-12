import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic>? initialData;

  const ReportDetailsScreen({
    super.key,
    required this.reportId,
    this.initialData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _report = widget.initialData;
      _isLoading = false;
    } else {
      _fetchReportDetails();
    }
  }

  Future<void> _fetchReportDetails() async {
    final isInitialLoad = _report == null;
    
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final report = await ApiService.instance.getReportDetails(widget.reportId);
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
          _errorMessage = null; // Clear error if successful
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Only show full error screen if we don't have data yet
          if (isInitialLoad) {
            _errorMessage = e.toString();
          } else {
            // Otherwise show a snackbar so current data stays visible
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to refresh: $e')),
            );
          }
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      await ApiService.instance.verifyReport(
        reportId: widget.reportId,
        isSame: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thank you! +10 Shield Points earned'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReportDetails(); // Refresh to show updated verification count
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify: $e')),
        );
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _handleShare() {
    if (_report == null) return;

    final text = '''
🚨 Scam Alert: ${_report!['category']}

${_report!['description']}

${_report!['target'] != null ? 'Target: ${_report!['target']}\n' : ''}
Reported via FraudShield - Stay Safe!
''';

    Share.share(text);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _handleShare,
              tooltip: 'Share',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _report == null
                  ? const Center(child: Text('Report not found'))
                  : RefreshIndicator(
                      onRefresh: _fetchReportDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildDescriptionCard(),
                            if (_report!['target'] != null) ...[
                              const SizedBox(height: 16),
                              _buildTargetCard(),
                            ],
                            if (_report!['evidence'] != null &&
                                (_report!['evidence'] as Map).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildEvidenceCard(),
                            ],
                            const SizedBox(height: 16),
                            _buildReporterCard(),
                            const SizedBox(height: 16),
                            _buildVerificationCard(),
                            const SizedBox(height: 16),
                            _buildActionButtons(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReportDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  (_report!['category'] ?? 'SCAM').toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_report!['status'] ?? 'PENDING').toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(_report!['createdAt']),
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          if (_report!['latitude'] != null && _report!['longitude'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Location: ${_report!['latitude']?.toStringAsFixed(4)}, ${_report!['longitude']?.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _report!['description'] ?? 'No description provided',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Target',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _report!['target'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(
                    _report!['target'].toString(),
                    'Target',
                  ),
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard() {
    final evidence = _report!['evidence'] as Map<String, dynamic>;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, size: 20, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'Evidence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...evidence.entries.map((entry) {
            if (entry.key == 'evidence_url') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    // TODO: Open image viewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image viewer coming soon')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image, size: 18, color: Colors.purple),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Evidence Image',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReporterCard() {
    final reporterTrust = _report!['reporterTrust'];
    if (reporterTrust == null) return const SizedBox.shrink();

    final score = reporterTrust['score'] ?? 0;
    final badges = reporterTrust['badges'] as List? ?? [];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Reporter Trust',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.verified_user,
                size: 24,
                color: _getTrustColor(score),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Score: $score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTrustColor(score),
                    ),
                  ),
                  Text(
                    _getTrustLabel(score),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        badge.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final verifications = _report!['_count']?['verifications'] ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, size: 20, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Community Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verifications.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  verifications == 1
                      ? 'person confirmed this scam'
                      : 'people confirmed this scam',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isVerifying ? null : _handleVerify,
            icon: _isVerifying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isVerifying ? 'Verifying...' : 'I Experienced This Too'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Earn +10 Shield Points for verifying',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor() {
    final status = (_report!['status'] ?? 'PENDING').toString().toUpperCase();
    switch (status) {
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getTrustColor(int score) {
    if (score >= 50) return Colors.purple;
    if (score >= 20) return Colors.blue;
    if (score > 0) return Colors.green;
    return Colors.grey;
  }

  String _getTrustLabel(int score) {
    if (score >= 50) return 'Elite Reporter';
    if (score >= 20) return 'Trusted Reporter';
    if (score > 0) return 'New Reporter';
    return 'Unknown';
  }
}

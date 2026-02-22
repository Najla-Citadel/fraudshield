import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _transaction;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await ApiService.instance.getJournalDetails(widget.transactionId);
      if (mounted) {
        setState(() {
          _transaction = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getColorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE': return AppColors.accentGreen;
      case 'SUSPICIOUS': return Colors.orangeAccent;
      case 'BLOCKED': return Colors.redAccent;
      case 'SCAMMED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getColorForScore(int score) {
    if (score >= 80) return Colors.redAccent;
    if (score >= 40) return Colors.orangeAccent;
    return AppColors.accentGreen;
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'URL': return LucideIcons.link;
      case 'PHONE': return LucideIcons.phone;
      case 'BANK': return LucideIcons.building;
      case 'DOC': return LucideIcons.fileText;
      case 'MANUAL': return LucideIcons.plusCircle;
      default: return LucideIcons.shieldCheck;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Scan Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGreen));
    }

    if (_error != null || _transaction == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load details',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
               _error ?? 'Transaction not found',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final status = _transaction!['status'] ?? 'UNKNOWN';
    final statusColor = _getColorForStatus(status);
    final type = _transaction!['checkType'] ?? 'UNKNOWN';
    final metadata = _transaction!['metadata'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Top Overview Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconForType(type), color: statusColor, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _transaction!['target'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(_transaction!['createdAt']),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // AI Breakdown Section
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'RISK ASSESSMENT',
            style: TextStyle(
              color: Colors.white,
               fontSize: 14,
               fontWeight: FontWeight.bold,
               letterSpacing: 1.5,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
               _buildRiskRow(
                 'Risk Score',
                 '${_transaction!['riskScore'] ?? 0}/100',
                 _getColorForScore(_transaction!['riskScore'] ?? 0),
                  isFirst: true,
               ),
               if (metadata.containsKey('threats') && (metadata['threats'] as List).isNotEmpty)
                 _buildRiskRow(
                   'Identified Threats',
                   (metadata['threats'] as List).join(', '),
                   Colors.redAccent,
                 ),
               if (metadata.containsKey('riskLevel'))
                 _buildRiskRow(
                   'Comm. Risk Level',
                   (metadata['riskLevel'] as String).toUpperCase(),
                   metadata['riskLevel'] == 'high' ? Colors.redAccent : Colors.orangeAccent,
                 ),
               if (metadata.containsKey('communityReports'))
                 _buildRiskRow(
                   'Community Reports',
                   '${metadata['communityReports']}',
                   Colors.grey,
                 ),
               if (metadata.containsKey('safe') && metadata['safe'] == true)
                 _buildRiskRow(
                   'Google Safe Browsing',
                   'Verified Clean',
                   AppColors.accentGreen,
                 ),
               _buildRiskRow(
                 'Check ID',
                 _transaction!['id'].toString().split('-').last,
                 Colors.grey,
                 isLast: true,
               ),
            ],
          ),
        ),

        if (type == 'MANUAL' || _transaction!['amount'] != null) ...[
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
            child: Text(
              'PAYMENT DETAILS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_transaction!['merchant'] != null)
                  _buildRiskRow('Recipient', _transaction!['merchant'], Colors.white, isFirst: true),
                if (_transaction!['amount'] != null)
                  _buildRiskRow('Amount', 'RM ${_transaction!['amount']}', AppColors.accentGreen),
                if (_transaction!['paymentMethod'] != null)
                  _buildRiskRow('Method', _transaction!['paymentMethod'], Colors.grey),
                if (_transaction!['platform'] != null)
                  _buildRiskRow('Platform', _transaction!['platform'], Colors.grey),
                if (_transaction!['notes'] != null && _transaction!['notes'].toString().isNotEmpty)
                  _buildRiskRow('Notes', _transaction!['notes'], Colors.grey, isLast: true),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        if (status.toUpperCase() != 'SCAMMED')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showReportDialog,
              icon: const Icon(LucideIcons.megaphone),
              label: const Text('REPORT THIS TRANSACTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        
        if (status.toUpperCase() == 'SCAMMED' && _transaction!['reportId'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'This transaction has been reported. Our team is investigating.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 48),
      ],
    );
  }

  void _showReportDialog() {
    final descriptionController = TextEditingController(text: _transaction!['notes'] ?? '');
    String selectedCategory = _transaction!['platform'] ?? 'Others';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.deepNavy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Fraud',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us what happened. This will help protect others.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Incident Description',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.fileText, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ['Shopee', 'Facebook', 'WhatsApp', 'Investment', 'Other'].contains(selectedCategory) 
                  ? selectedCategory : 'Other',
              dropdownColor: const Color(0xFF0B1121),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Scam Category',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.tag, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: ['Shopee', 'Facebook', 'WhatsApp', 'Investment', 'Other'].map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) => selectedCategory = val!,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _convertToReport(descriptionController.text, selectedCategory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'SUBMIT SCAM REPORT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToReport(String description, String category) async {
    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      await ApiService.instance.convertToScamReport(
        journalId: widget.transactionId,
        description: description,
        category: category,
      );

      _fetchDetails();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scam report submitted successfully!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    }
  }

  Widget _buildRiskRow(String label, String value, Color valueColor, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

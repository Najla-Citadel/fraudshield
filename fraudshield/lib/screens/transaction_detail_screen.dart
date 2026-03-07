import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../design_system/components/app_back_button.dart';
import '../design_system/components/app_snackbar.dart';
import '../widgets/error_state.dart';
import 'dart:math' as math;
import '../design_system/components/app_loading_indicator.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _transaction;
  String? _error;
  bool _notesExpanded = false;
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _fetchDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final data =
          await ApiService.instance.getJournalDetails(widget.transactionId);
      if (mounted) {
        setState(() {
          _transaction = data;
          _isLoading = false;
        });
        _animController.forward();
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return DesignTokens.colors.accentGreen;
      case 'SUSPICIOUS':
        return DesignTokens.colors.warning;
      case 'BLOCKED':
        return DesignTokens.colors.error;
      case 'SCAMMED':
        return DesignTokens.colors.error;
      default:
        return DesignTokens.colors.textGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return LucideIcons.shieldCheck;
      case 'SUSPICIOUS':
        return LucideIcons.alertTriangle;
      case 'BLOCKED':
        return LucideIcons.shieldOff;
      case 'SCAMMED':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.shield;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 75) return DesignTokens.colors.error;
    if (score >= 40) return DesignTokens.colors.warning;
    return DesignTokens.colors.accentGreen;
  }

  String _scoreLabel(int score) {
    if (score >= 75) return 'High Risk';
    if (score >= 40) return 'Medium Risk';
    return 'Low Risk';
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'URL':
        return LucideIcons.link;
      case 'PHONE':
        return LucideIcons.phone;
      case 'BANK':
        return LucideIcons.building;
      case 'DOC':
        return LucideIcons.fileText;
      case 'AUTO_CAPTURE':
        return LucideIcons.cpu;
      default:
        return LucideIcons.creditCard;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}  •  '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatAmount(dynamic raw) {
    if (raw == null) return '—';
    final amt = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (amt == null) return '—';
    final prefix = amt < 0 ? '– RM ' : '+ RM ';
    return '$prefix${amt.abs().toStringAsFixed(2)}';
  }

  bool get _isOutgoing {
    final amt = _transaction!['amount'];
    if (amt == null) return false;
    final v = amt is num ? amt.toDouble() : double.tryParse(amt.toString());
    return (v ?? 0) < 0;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      useSafeArea: false,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: AppLoadingIndicator.center());
    }

    if (_error != null || _transaction == null) {
      return ErrorState(
          onRetry: _fetchDetails, message: _error ?? 'Transaction not found');
    }

    final status = (_transaction!['status'] ?? 'UNKNOWN') as String;
    final type = (_transaction!['checkType'] ?? 'MANUAL') as String;
    final score = (_transaction!['riskScore'] ?? 0) as int;
    final sColor = _statusColor(status);
    final metadata = _transaction!['metadata'] as Map<String, dynamic>? ?? {};
    final notes = _transaction!['notes']?.toString() ?? '';
    final recipient =
        _transaction!['merchant'] ?? _transaction!['target'] ?? '—';
    final checkId =
        _transaction!['id'].toString().split('-').last.toUpperCase();

    return CustomScrollView(
      slivers: [
        // ── Collapsing hero appbar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: DesignTokens.colors.backgroundDark,
          leading: const AppBackButton(),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.copy, color: Colors.white, size: 20),
              tooltip: 'Copy ID',
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _transaction!['id'].toString()));
                AppSnackBar.showInfo(context, 'Transaction ID copied');
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHero(status, type, score, sColor),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Amount + recipient card ─────────────────────────────────
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildAmountRow(score, recipient),
                    const Divider(color: Color(0xFF1E2D45), height: 1),
                    _buildInfoRow(
                      icon: LucideIcons.calendar,
                      label: 'Date',
                      value: _formatDate(_transaction!['createdAt']),
                    ),
                    if (_transaction!['paymentMethod'] != null) ...[
                      const Divider(color: Color(0xFF1E2D45), height: 1),
                      _buildInfoRow(
                        icon: LucideIcons.creditCard,
                        label: 'Method',
                        value: _transaction!['paymentMethod'].toString(),
                      ),
                    ],
                    if (_transaction!['platform'] != null) ...[
                      const Divider(color: Color(0xFF1E2D45), height: 1),
                      _buildInfoRow(
                        icon: _typeIcon(type),
                        label: 'Source',
                        value: _transaction!['platform'].toString(),
                      ),
                    ],
                    const Divider(color: Color(0xFF1E2D45), height: 1),
                    _buildInfoRow(
                      icon: LucideIcons.hash,
                      label: 'Check ID',
                      value: checkId,
                      valueStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Risk Assessment ─────────────────────────────────────────
              _buildSectionLabel('Risk Assessment'),
              const SizedBox(height: 8),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Gauge
                          AnimatedBuilder(
                            animation: _scoreAnim,
                            builder: (_, __) => SizedBox(
                              width: 72,
                              height: 72,
                              child: CustomPaint(
                                painter: _RiskGaugePainter(
                                  score / 100.0 * _scoreAnim.value,
                                  _scoreColor(score),
                                ),
                                child: Center(
                                  child: Text(
                                    '$score',
                                    style: TextStyle(
                                      color: _scoreColor(score),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _scoreLabel(score),
                                  style: TextStyle(
                                    color: _scoreColor(score),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  score == 0
                                      ? 'No threats detected for this transaction.'
                                      : 'This transaction has elevated risk signals. Review carefully before proceeding.',
                                  style: const TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Optional threat tags
                    if (metadata.containsKey('threats') &&
                        (metadata['threats'] as List).isNotEmpty) ...[
                      const Divider(color: Color(0xFF1E2D45), height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Threats Detected',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: (metadata['threats'] as List)
                                  .map((t) => _threatChip(t.toString()))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (metadata.containsKey('communityReports') &&
                        (metadata['communityReports'] as int? ?? 0) > 0) ...[
                      const Divider(color: Color(0xFF1E2D45), height: 1),
                      _buildInfoRow(
                        icon: LucideIcons.users,
                        label: 'Community Reports',
                        value: '${metadata['communityReports']} report(s)',
                        valueColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Notes ──────────────────────────────────────────────────
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionLabel('Notes'),
                const SizedBox(height: 8),
                _buildSectionCard(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _notesExpanded = !_notesExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedCrossFade(
                            firstChild: Text(
                              notes,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  height: 1.6),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              notes,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  height: 1.6),
                            ),
                            crossFadeState: _notesExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 250),
                          ),
                          if (notes.length > 120) ...[
                            const SizedBox(height: 8),
                            Text(
                              _notesExpanded ? 'Show less' : 'Show more',
                              style: TextStyle(
                                  color: DesignTokens.colors.accentGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Safety tips for suspicious ──────────────────────────────
              if (status.toUpperCase() == 'SUSPICIOUS' ||
                  status.toUpperCase() == 'BLOCKED') ...[
                _buildWarningBanner(score),
                const SizedBox(height: 16),
              ],

              // ── Report CTA ─────────────────────────────────────────────
              if (status.toUpperCase() != 'SCAMMED')
                _buildReportButton()
              else
                _buildReportedBanner(),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero(String status, String type, int score, Color sColor) {
    final isOut = _isOutgoing;
    final amtStr = _formatAmount(_transaction!['amount']);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sColor.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(status), color: sColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Amount
            if (_transaction!['amount'] != null)
              Text(
                amtStr,
                style: TextStyle(
                  color:
                      isOut ? const Color(0xFFF87171) : const Color(0xFF22D483),
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            const SizedBox(height: 4),
            // Recipient
            Text(
              _transaction!['merchant'] ?? _transaction!['target'] ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _buildSectionCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.colors.glassDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
          child: child,
        ),
      );

  Widget _buildAmountRow(int score, String recipient) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _scoreColor(score).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(LucideIcons.user, color: _scoreColor(score), size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recipient',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  recipient,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    TextStyle? valueStyle,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valueStyle ??
                    TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );

  Widget _threatChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildWarningBanner(int score) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.alertTriangle,
                color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proceed with Caution',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    "Do not transfer money to unknown recipients. Verify the account holder's identity before proceeding.",
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildReportButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _showReportDialog,
          icon: const Icon(LucideIcons.megaphone, size: 18),
          label: const Text(
            'Report This Transaction',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );

  Widget _buildReportedBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.checkCircle, color: Color(0xFF22D483), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reported & Under Review\nOur team is investigating this transaction.',
                style:
                    TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      );

  // ─── Report Sheet ──────────────────────────────────────────────────────────
  void _showReportDialog() {
    final descCtrl =
        TextEditingController(text: _transaction!['notes']?.toString() ?? '');
    String selectedCategory = 'Other';
    final categories = [
      'Shopee',
      'Facebook',
      'WhatsApp',
      'Investment',
      'E-Commerce',
      'Banking',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(LucideIcons.megaphone,
                      color: Color(0xFFF87171), size: 22),
                  SizedBox(width: 10),
                  Text('Report Fraud',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Help protect the community by reporting this suspicious transaction.',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Description
              TextField(
                controller: descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe what happened...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  filled: true,
                  fillColor: const Color(0xFF1A2332),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),

              // Category chips
              const Text('Category',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .map((c) => GestureDetector(
                          onTap: () => setSS(() => selectedCategory = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedCategory == c
                                  ? const Color(0xFFEF4444)
                                      .withOpacity(0.15)
                                  : const Color(0xFF1A2332),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedCategory == c
                                    ? const Color(0xFFEF4444)
                                        .withOpacity(0.6)
                                    : const Color(0xFF1E2D45),
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: selectedCategory == c
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () =>
                      _convertToReport(descCtrl.text, selectedCategory),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Submit Scam Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
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
        AppSnackBar.showSuccess(context, '✅ Scam report submitted. Thank you!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Failed: $e');
      }
    }
  }
}

// ─── Risk Gauge Painter ───────────────────────────────────────────────────────

class _RiskGaugePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;

  _RiskGaugePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;
    const startAngle = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweep, false, trackPaint);

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, sweep * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RiskGaugePainter old) =>
      old.progress != progress || old.color != color;
}

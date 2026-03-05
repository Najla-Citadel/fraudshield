import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';

import 'transaction_detail_screen.dart';
import 'log_payment_sheet.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';

class TransactionJournalScreen extends StatefulWidget {
  const TransactionJournalScreen({super.key});

  @override
  State<TransactionJournalScreen> createState() =>
      _TransactionJournalScreenState();
}

class _TransactionJournalScreenState extends State<TransactionJournalScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String? _error;
  String _selectedFilter = 'ALL';
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _filters = [
    'ALL',
    'URL',
    'PHONE',
    'BANK',
    'DOC',
    'MANUAL',
    'AUTO_CAPTURE'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _fetchTransactions(loadMore: true);
      }
    }
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _offset = 0;
        _transactions.clear();
      });
    }

    try {
      final String? typeFilter =
          _selectedFilter == 'ALL' ? null : _selectedFilter;
      final data = await ApiService.instance.getTransactionJournal(
        type: typeFilter,
        offset: _offset,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _transactions.addAll(data['results'] ?? []);
          } else {
            _transactions = data['results'] ?? [];
          }
          _hasMore = data['hasMore'] ?? false;
          _offset += 20;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _setFilter(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _fetchTransactions();
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'URL':
        return LucideIcons.link;
      case 'PHONE':
        return LucideIcons.phone;
      case 'BANK':
        return LucideIcons.building;
      case 'DOC':
        return LucideIcons.fileText;
      case 'MANUAL':
        return LucideIcons.plusCircle;
      case 'AUTO_CAPTURE':
        return LucideIcons.cpu;
      case 'QR':
        return LucideIcons.qrCode;
      default:
        return LucideIcons.shieldCheck;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'SAFE':
        return const Color(0xFF22D483);
      case 'SUSPICIOUS':
        return const Color(0xFFF59E0B);
      case 'BLOCKED':
        return const Color(0xFFEF4444);
      case 'SCAMMED':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(dynamic raw) {
    if (raw == null) return '';
    final amt = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (amt == null) return '';
    final prefix = amt < 0 ? '-' : '+';
    return '$prefix RM ${amt.abs().toStringAsFixed(2)}';
  }

  Color _amountColor(dynamic raw) {
    if (raw == null) return Colors.grey;
    final amt = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (amt == null) return Colors.grey;
    return amt < 0 ? const Color(0xFFF87171) : const Color(0xFF22D483);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate == today) {
        return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (checkDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: const Text('Security Journal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedFilter = filter;
                        _transactions.clear();
                        _offset = 0;
                        _hasMore = true;
                      });
                      _fetchTransactions();
                    },
                    backgroundColor: const Color(0xFF1E293B),
                    selectedColor: AppColors.accentGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.deepNavy : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Ledger List
          _buildBody(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualLogForm,
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.deepNavy,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Log Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showManualLogForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogPaymentSheet(
        onLogSuccess: () => _fetchTransactions(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _transactions.isEmpty) {
      return Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) => const SkeletonCard(
              height: 80, margin: EdgeInsets.only(bottom: 12)),
        ),
      );
    }

    if (_error != null && _transactions.isEmpty) {
      return Expanded(
        child: ErrorState(
          onRetry: () => _fetchTransactions(),
          message: _error!,
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E2D45)),
                ),
                child: Icon(LucideIcons.list,
                    color: Colors.white.withValues(alpha: 0.2), size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nothing here yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedFilter == 'ALL'
                    ? 'Your transaction history will appear here.'
                    : 'No $_selectedFilter transactions found.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentGreen),
              ),
            );
          }

          final tx = _transactions[index];
          final type = (tx['checkType'] ?? 'MANUAL') as String;
          final status = (tx['status'] ?? 'SAFE') as String;
          final merchant = tx['merchant']?.toString() ??
              tx['target']?.toString() ??
              'Unknown';
          final date = _formatDate(tx['createdAt'] ?? '');
          final statusColor = _getColorForStatus(status);
          final icon = _getIconForType(type);
          final amtStr = _formatAmount(tx['amount']);
          final amtColor = _amountColor(tx['amount']);
          final riskScore = (tx['riskScore'] ?? 0) as int;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailScreen(transactionId: tx['id'] as String),
              ),
            ).then((_) => _fetchTransactions()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E2D45)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left status accent bar
                      Container(width: 4, color: statusColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              // Icon badge
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              // Merchant + meta
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      merchant,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                                alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            date,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Amount + risk score
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (amtStr.isNotEmpty)
                                    Text(
                                      amtStr,
                                      style: TextStyle(
                                        color: amtColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    Icon(LucideIcons.chevronRight,
                                        color: const Color(0xFF475569),
                                        size: 18),
                                  if (riskScore > 0) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '$riskScore/100',
                                      style: TextStyle(
                                        color: riskScore >= 75
                                            ? const Color(0xFFF87171)
                                            : const Color(0xFFF59E0B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

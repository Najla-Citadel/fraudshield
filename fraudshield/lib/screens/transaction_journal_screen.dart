import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/adaptive_scaffold.dart';
import 'transaction_detail_screen.dart';

class TransactionJournalScreen extends StatefulWidget {
  const TransactionJournalScreen({super.key});

  @override
  State<TransactionJournalScreen> createState() => _TransactionJournalScreenState();
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

  final List<String> _filters = ['ALL', 'URL', 'PHONE', 'BANK', 'DOC', 'MANUAL'];

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      final String? typeFilter = _selectedFilter == 'ALL' ? null : _selectedFilter;
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
      case 'URL': return LucideIcons.link;
      case 'PHONE': return LucideIcons.phone;
      case 'BANK': return LucideIcons.building;
      case 'DOC': return LucideIcons.fileText;
      case 'MANUAL': return LucideIcons.plusCircle;
      default: return LucideIcons.shieldCheck;
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
        title: const Text('Security Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        label: const Text('Log Payment', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showManualLogForm() {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMethod = 'Bank Transfer';
    String selectedPlatform = 'WhatsApp';

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Transaction',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: merchantController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Recipient / Merchant Name',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(LucideIcons.user, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (RM)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(LucideIcons.banknote, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                dropdownColor: const Color(0xFF0B1121),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(LucideIcons.creditCard, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: ['Bank Transfer', 'DuitNow', 'E-Wallet', 'COD'].map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (val) => selectedMethod = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlatform,
                dropdownColor: const Color(0xFF0B1121),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Platform',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(LucideIcons.layout, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: ['WhatsApp', 'Shopee', 'Facebook', 'Carousell', 'Telegram', 'Other'].map((p) {
                  return DropdownMenuItem(value: p, child: Text(p));
                }).toList(),
                onChanged: (val) => selectedPlatform = val!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                   labelText: 'Notes (Optional)',
                   labelStyle: const TextStyle(color: Colors.grey),
                   prefixIcon: const Icon(LucideIcons.fileText, color: Colors.grey),
                   filled: true,
                   fillColor: const Color(0xFF1E293B),
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (merchantController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in required fields')),
                      );
                      return;
                    }

                    try {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      
                      await ApiService.instance.logTransaction(
                        amount: double.parse(amountController.text),
                        merchant: merchantController.text,
                        paymentMethod: selectedMethod,
                        platform: selectedPlatform,
                        notes: notesController.text,
                      );

                      _fetchTransactions();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'SAVE TO JOURNAL',
                    style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _transactions.isEmpty) {
      return const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)));
    }

    if (_error != null && _transactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load journal',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
               _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchTransactions(),
               style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.deepNavy,
                ),
              child: const Text('RETRY'),
            ),
            ],
          ),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.5)),
                ),
                child: Icon(LucideIcons.shield, color: Colors.grey.withOpacity(0.5), size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'No logs found',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your scan history for $_selectedFilter will appear here.',
                style: const TextStyle(color: Colors.grey),
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
        final type = tx['checkType'] ?? 'UKNOWN';
        final status = tx['status'] ?? 'SAFE';
        final target = tx['target'] ?? '';
        final date = _formatDate(tx['createdAt'] ?? '');
        
        final statusColor = _getColorForStatus(status);
        final icon = _getIconForType(type);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(16),
             side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transactionId: tx['id']),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              ' • $date',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}

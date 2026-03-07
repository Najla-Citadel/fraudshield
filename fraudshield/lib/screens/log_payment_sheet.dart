import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/components/app_loading_indicator.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../constants/colors.dart';

class LogPaymentSheet extends StatefulWidget {
  final VoidCallback onLogSuccess;

  const LogPaymentSheet({super.key, required this.onLogSuccess});

  @override
  State<LogPaymentSheet> createState() => _LogPaymentSheetState();
}

class _LogPaymentSheetState extends State<LogPaymentSheet> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMethod = 'Bank Transfer';
  String _selectedPlatform = 'WhatsApp';
  String _selectedCategory = 'BANK';
  bool _isSubmitting = false;
  bool _isIncome = false; // Default to Money Out (Expense)

  Timer? _debounce;
  bool _isChecking = false;
  Map<String, dynamic>? _riskCheckResult;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTargetChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _riskCheckResult = null;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _riskCheckResult = null;
    });

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final Map<String, dynamic> result =
            await ApiService.instance.lookupPaymentRisk(
          type: _selectedCategory.toLowerCase(),
          value: value.trim(),
        );
        if (mounted) {
          setState(() {
            _riskCheckResult = result;
            _isChecking = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isChecking = false);
        }
      }
    });
  }

  Widget _buildRiskBadge() {
    if (_merchantController.text.trim().isEmpty) return const SizedBox.shrink();

    if (_isChecking) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            SizedBox(
                width: 16,
                height: 16,
                child: AppLoadingIndicator(
                    color: Colors.blueAccent, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Checking community database...',
                style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
          ],
        ),
      );
    }

    if (_riskCheckResult == null) return const SizedBox.shrink();

    final bool found = _riskCheckResult!['found'] ?? false;
    if (!found) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: const [
            Icon(LucideIcons.checkCircle2,
                color: AppColors.accentGreen, size: 20),
            SizedBox(width: 12),
            Expanded(
                child: Text('No community reports found. Safe to proceed.',
                    style:
                        TextStyle(color: AppColors.accentGreen, fontSize: 13))),
          ],
        ),
      );
    }

    final String riskLevel = _riskCheckResult!['riskLevel'] ?? 'unknown';
    final int count = _riskCheckResult!['communityReports'] ?? 0;
    final String rec = _riskCheckResult!['recommendation'] ?? '';

    Color badgeColor = Colors.orangeAccent;
    IconData badgeIcon = LucideIcons.alertTriangle;
    if (riskLevel == 'high') {
      badgeColor = Colors.redAccent;
      badgeIcon = LucideIcons.alertOctagon;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Caution: $count Report(s)',
                    style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  rec,
                  style: TextStyle(
                      color: badgeColor.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_merchantController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      double amount = double.parse(_amountController.text);
      if (!_isIncome) {
        amount = -amount.abs(); // Force negative for Money Out
      } else {
        amount = amount.abs(); // Force positive for Money In
      }

      await ApiService.instance.logTransaction(
        amount: amount,
        merchant: _merchantController.text,
        paymentMethod: _selectedMethod,
        platform: _selectedPlatform,
        notes: _notesController.text,
        checkType: _selectedCategory,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onLogSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF0B1121),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Log Category',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.tag, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              items: ['BANK', 'PHONE', 'URL', 'DOC', 'MANUAL'].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCategory = val!);
                _onTargetChanged(_merchantController.text); // Re-trigger lookup
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              onChanged: _onTargetChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Recipient / Merchant Name',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.user, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),

            // Risk Badge injected here
            _buildRiskBadge(),
            if (_riskCheckResult == null && !_isChecking)
              const SizedBox(height: 16),

            // In/Out Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isIncome
                            ? AppColors.accentGreen.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _isIncome
                                ? AppColors.accentGreen
                                : Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.arrowDownLeft,
                              color: _isIncome
                                  ? AppColors.accentGreen
                                  : Colors.grey,
                              size: 18),
                          const SizedBox(width: 8),
                          Text('MONEY IN',
                              style: TextStyle(
                                  color: _isIncome
                                      ? AppColors.accentGreen
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIncome = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isIncome
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: !_isIncome
                                ? Colors.redAccent
                                : Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.arrowUpRight,
                              color:
                                  !_isIncome ? Colors.redAccent : Colors.grey,
                              size: 18),
                          const SizedBox(width: 8),
                          Text('MONEY OUT',
                              style: TextStyle(
                                  color: !_isIncome
                                      ? Colors.redAccent
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(LucideIcons.banknote, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              dropdownColor: const Color(0xFF0B1121),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Payment Method',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(LucideIcons.creditCard, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              items:
                  ['Bank Transfer', 'DuitNow', 'E-Wallet', 'COD'].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPlatform,
              dropdownColor: const Color(0xFF0B1121),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Platform',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.layout, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              items: [
                'WhatsApp',
                'Shopee',
                'Facebook',
                'Carousell',
                'Telegram',
                'Other'
              ].map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (val) => setState(() => _selectedPlatform = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(LucideIcons.fileText, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const AppLoadingIndicator(color: AppColors.deepNavy)
                    : const Text(
                        'SAVE TO JOURNAL',
                        style: TextStyle(
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// lib/screens/fraud_check_screen.dart
import 'package:flutter/material.dart';
import '../services/risk_evaluator.dart';
import '../services/supabase_service.dart';
import '../utils/validators.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/core/custom_text_field.dart';
import '../widgets/core/primary_button.dart';
import '../widgets/core/section_header.dart';
import '../widgets/core/status_badge.dart';

class FraudCheckScreen extends StatefulWidget {
  const FraudCheckScreen({super.key});

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen> {
  final _inputController = TextEditingController();
  final _supabase = SupabaseService.instance;
  
  String _selectedType = 'Phone No';
  final List<String> _types = ['Phone No', 'URL', 'Bank Account', 'Document'];

  bool _loading = false;
  RiskResult? _result;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _analyze() async {
    final value = _inputController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value to check')),
      );
      return;
    }

    // Validate input based on type
    String? validationError;
    switch (_selectedType) {
      case 'Phone No':
        validationError = Validators.validatePhoneNumber(value);
        break;
      case 'URL':
        validationError = Validators.validateUrl(value);
        break;
      case 'Bank Account':
        validationError = Validators.validateBankAccount(value);
        break;
      case 'Document':
        // No specific validation for document names
        break;
    }

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    // Simulate network delay for "AI" feel
    await Future.delayed(const Duration(seconds: 2));

    // Sanitize input before processing
    String sanitizedValue = value;
    switch (_selectedType) {
      case 'Phone No':
        sanitizedValue = Validators.sanitizePhoneNumber(value);
        break;
      case 'URL':
        sanitizedValue = Validators.sanitizeUrl(value);
        break;
      case 'Bank Account':
        sanitizedValue = Validators.sanitizeBankAccount(value);
        break;
      default:
        sanitizedValue = Validators.sanitizeInput(value);
    }

    final result = RiskEvaluator.evaluate(type: _selectedType, value: sanitizedValue);

    // Save to database
    try {
      await _supabase.createFraudCheck(
        checkType: _selectedType,
        value: sanitizedValue,
        riskScore: result.score,
        riskLevel: result.level,
        reasons: result.reasons,
      );
    } catch (e) {
      // Log error but don't block UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check completed but failed to save: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _result = result;
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Fraud Check'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            // 🛡️ INPUT CARD
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SectionHeader(title: 'What to check?', actionLabel: ''),
                   const SizedBox(height: AppSpacing.m),
                   
                   // TYPE SELECTOR (Custom Chips)
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: Row(
                       children: _types.map((type) {
                         final isSelected = _selectedType == type;
                         return Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: ChoiceChip(
                             label: Text(type),
                             selected: isSelected,
                             selectedColor: AppColors.primaryLight,
                             backgroundColor: AppColors.backgroundLight,
                             labelStyle: TextStyle(
                               color: isSelected ? AppColors.primary : AppColors.textSecondary,
                               fontWeight: FontWeight.bold,
                             ),
                             onSelected: (val) {
                               if (val) setState(() => _selectedType = type);
                             },
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(20),
                               side: BorderSide(
                                 color: isSelected ? AppColors.primary : Colors.transparent,
                               ),
                             ),
                           ),
                         );
                       }).toList(),
                     ),
                   ),

                   const SizedBox(height: AppSpacing.l),

                   // INPUT FIELD
                   CustomTextField(
                     label: 'Target Value',
                     controller: _inputController,
                     hintText: _getHintText(),
                     prefixIcon: _getIconForType(),
                   ),

                   const SizedBox(height: AppSpacing.xl),

                   PrimaryButton(
                     label: 'Analyze Risk',
                     onPressed: _loading ? null : _analyze,
                     isLoading: _loading,
                     icon: Icons.radar,
                   ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 📊 RESULT SECTION
            if (_result != null)
              _ResultCard(result: _result!, onReset: _reset),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedType) {
      case 'Phone No': return '+1 234 567 890';
      case 'URL': return 'https://example.com';
      case 'Bank Account': return '1234-5678-9012';
      case 'Document': return 'ID / Filename';
      default: return 'Enter value';
    }
  }

  IconData _getIconForType() {
    switch (_selectedType) {
      case 'Phone No': return Icons.phone;
      case 'URL': return Icons.link;
      case 'Bank Account': return Icons.account_balance;
      case 'Document': return Icons.description;
      default: return Icons.text_fields;
    }
  }
}

class _ResultCard extends StatelessWidget {
  final RiskResult result;
  final VoidCallback onReset;

  const _ResultCard({required this.result, required this.onReset});

  @override
  Widget build(BuildContext context) {
    // Determine color based on level
    final isHigh = result.level == 'high';
    final isMedium = result.level == 'medium';
    final color = isHigh ? AppColors.error : (isMedium ? AppColors.warning : AppColors.success);
    final icon = isHigh ? Icons.gpp_bad : (isMedium ? Icons.warning_amber : Icons.gpp_good);
    final status = isHigh ? BadgeStatus.danger : (isMedium ? BadgeStatus.warning : BadgeStatus.safe);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
         boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: AppSpacing.m),
          
          Text(
            'Risk Score: ${result.score}/100',
            style: AppTypography.h2.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.s),
          
          StatusBadge(label: result.level.toUpperCase(), status: status),
          
          const SizedBox(height: AppSpacing.l),
          
          const Divider(),
          
          const SizedBox(height: AppSpacing.m),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Analysis Report:', style: AppTypography.h3),
          ),
          const SizedBox(height: AppSpacing.s),
          
          ...result.reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: AppColors.textSecondary),
                Expanded(child: Text(reason, style: AppTypography.bodyM)),
              ],
            ),
          )),

          const SizedBox(height: AppSpacing.l),

          PrimaryButton(
            label: 'Check Another',
            onPressed: onReset,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

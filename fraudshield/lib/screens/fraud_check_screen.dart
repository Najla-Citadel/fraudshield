import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/adaptive_segmented_control.dart';
import '../widgets/glass_card.dart';

class FraudCheckScreen extends StatefulWidget {
  const FraudCheckScreen({super.key});

  @override
  State<FraudCheckScreen> createState() => _FraudCheckScreenState();
}

class _FraudCheckScreenState extends State<FraudCheckScreen> {
  String _selectedType = 'Phone No';
  final _inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Fraud Check',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 🧭 Title
            Text(
              'Think it might be a scam?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check it instantly with FraudShield.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 30),

            // 💠 Selection buttons

            // 💠 Selection buttons
            SizedBox(
              width: double.infinity,
              child: AdaptiveSegmentedControl<String>(
                groupValue: _selectedType,
                onValueChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _inputController.clear();
                  });
                },
                children: const {
                  'Phone No': Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Phone')),
                  'URL': Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('URL')),
                  'Bank Acc': Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Bank')),
                  'Document': Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Doc')),
                },
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 Input field
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Enter ${_selectedType.toLowerCase()}',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _selectedType == 'Document'
                    ? IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload file clicked')),
                          );
                        },
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            // 🟦 Check Now button
            AdaptiveButton(
              text: 'Check Now',
              onPressed: () {
                if (_inputController.text.isEmpty && _selectedType != 'Document') {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a value')),
                  );
                  return;
                }

                // Mock result for document since RiskEvaluator might not handle it or file path
                if (_selectedType == 'Document') {
                   // Mock delay
                   Future.delayed(const Duration(seconds: 1), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckResultScreen(
                            type: _selectedType,
                            value: 'Uploaded File',
                            result: RiskResult(level: 'low', score: 10, reasons: ['No malware found']),
                          ),
                        ),
                      );
                   });
                   return;
                }

                final result = RiskEvaluator.evaluate(
                  type: _selectedType,
                  value: _inputController.text.trim(),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckResultScreen(
                      type: _selectedType,
                      value: _inputController.text.trim(),
                      result: result,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // 🧠 Safety tips
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Stay protected:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text('• Never share your OTP or banking info.'),
                  Text('• Always verify official website URLs.'),
                  Text('• Report any suspicious message immediately.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔘 Reusable selectable button
}

// 🧾 Result Screen
class CheckResultScreen extends StatelessWidget {
  final String type;
  final String value;
  final RiskResult result;

  const CheckResultScreen({
    super.key,
    required this.type,
    required this.value,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = result.level == 'high';
    final isMedium = result.level == 'medium';

    final icon = isHigh
        ? Icons.warning_rounded
        : isMedium
            ? Icons.error_outline
            : Icons.verified_user;

    final color = isHigh
        ? Colors.red
        : isMedium
            ? Colors.orange
            : Colors.green;

    final title = isHigh
        ? 'High Risk Detected'
        : isMedium
            ? 'Suspicious Activity'
            : 'Looks Safe';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Fraud Check Result'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 90),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${type.toLowerCase()} checked',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // 🔢 Score
            Text(
              'Risk Score: ${result.score}/100',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // 📋 Reasons
            ...result.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}


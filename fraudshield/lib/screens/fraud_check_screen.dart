import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/risk_evaluator.dart';

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
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Fraud Check',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeButton('Phone No'),
                _buildTypeButton('URL'),
                _buildTypeButton('Bank Acc'),
                _buildTypeButton('Document'),

              ],
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_inputController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a value')),
                    );
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

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Check Now',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🧠 Safety tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
  Widget _buildTypeButton(String label) {
    final isSelected = _selectedType == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = label;
            _inputController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
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


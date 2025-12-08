import 'package:flutter/material.dart';
import '../constants/colors.dart';

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
            Text(
              'Try (Scam)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeButton('Phone No'),
                _buildTypeButton('URL'),
                _buildTypeButton('Document'),
              ],
            ),

            const SizedBox(height: 30),

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

                  // Random mock detection
                  final isSuspicious = DateTime.now().millisecond % 2 == 0;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckResultScreen(
                        type: _selectedType,
                        value: _inputController.text,
                        isSuspicious: isSuspicious,
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
  final bool isSuspicious;

  const CheckResultScreen({
    super.key,
    required this.type,
    required this.value,
    required this.isSuspicious,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isSuspicious ? Icons.warning_rounded : Icons.verified_user;
    final color = isSuspicious ? Colors.redAccent : Colors.green;
    final title = isSuspicious
        ? 'Suspicious Activity Detected!'
        : 'Everything Looks Safe!';
    final message = isSuspicious
        ? 'This ${type.toLowerCase()} appears to be suspicious. Please proceed with caution.'
        : 'No signs of fraud detected for this ${type.toLowerCase()}.';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Result'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 100),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

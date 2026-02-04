import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'report_history_screen.dart';

class ScamReportingScreen extends StatefulWidget {
  const ScamReportingScreen({super.key});

  @override
  State<ScamReportingScreen> createState() => _ScamReportingScreenState();
}

class _ScamReportingScreenState extends State<ScamReportingScreen> {
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Investment Scam';
  bool _reportSent = false;
  String _selectedEvidenceType = 'Phone Number';
  final _evidenceController = TextEditingController();
  String _reportType = 'Phone';

final List<String> _reportTypes = [
  'Phone',
  'Message',
  'Document',
  'Others',
];
  @override
  Widget build(BuildContext context) {
    if (_reportSent) {
      // ✅ After submit — show confirmation screen
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: const Text('Report Sent'),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 90),
                const SizedBox(height: 20),
                const Text(
                  'Your scam report is successfully sent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We will verify your report and inform you once any follow-up action has been taken.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _reportSent = false;
                      _phoneController.clear();
                      _descController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  child: const Text('Got It'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🧾 Main Report Form
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
  backgroundColor: AppColors.primaryBlue,
  title: const Text(
    'Scam Reporting',
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
    IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Report History',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportHistoryScreen(),
          ),
        );
      },
    ),
  ],
),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // 📱 Phone Number Field
            // 🧾 Evidence Type
Text(
  'Reports may be shared with relevant authorities for review',
  style: TextStyle(
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    fontSize: 16,
  ),
),
const SizedBox(height: 8),

Container(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButton<String>(
    value: _reportType,
    isExpanded: true,
    underline: const SizedBox(),
    items: _reportTypes.map((type) {
      return DropdownMenuItem(
        value: type,
        child: Text(type),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        _reportType = value!;
      });
    },
  ),
),

const SizedBox(height: 16),

if (_reportType == 'Phone') ...[
  TextField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    decoration: InputDecoration(
      labelText: 'Phone Number',
      filled: true,
      fillColor: Colors.white,
      prefixIcon: const Icon(Icons.phone_outlined),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  ),
],

if (_reportType == 'Others') ...[
  TextField(
    controller: _descController,
    maxLines: 3,
    decoration: InputDecoration(
      labelText: 'Describe the issue',
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  ),
],



const SizedBox(height: 20),

            // 🏷️ Scam Category
            Text(
              'Scam Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: 'Investment Scam',
                      child: Text('Investment Scam')),
                  DropdownMenuItem(
                      value: 'Fake Giveaway / Promo Scam',
                      child: Text('Fake Giveaway / Promo Scam')),
                  DropdownMenuItem(
                      value: 'Phishing Scam',
                      child: Text('Phishing Scam')),
                  DropdownMenuItem(
                      value: 'Job Scam', child: Text('Job Scam')),
                  DropdownMenuItem(
                      value: 'Love Scam', child: Text('Love Scam')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // 📝 Description
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📎 Upload Attachment (Mock)
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('File upload feature coming soon')));
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Evidence (Optional)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🟦 Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  bool isPhoneValid =
                    _reportType != 'Phone' || _phoneController.text.trim().isNotEmpty;

                  if (!isPhoneValid || _descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields.')),
                  );
                  return;
                  }


                  setState(() {
                    _reportSent = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}

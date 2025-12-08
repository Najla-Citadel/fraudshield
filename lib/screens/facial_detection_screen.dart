import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FacialDetectionScreen extends StatefulWidget {
  const FacialDetectionScreen({super.key});

  @override
  State<FacialDetectionScreen> createState() => _FacialDetectionScreenState();
}

class _FacialDetectionScreenState extends State<FacialDetectionScreen> {
  bool isScanning = false;
  bool? isSuspicious; // null = no result yet

  void _startScan() {
    setState(() {
      isScanning = true;
      isSuspicious = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isScanning = false;
        // Mock random result
        isSuspicious = DateTime.now().millisecond % 2 == 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Facial Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 🧠 Info
            Text(
              'Scan and verify faces to detect suspicious users or impersonators.',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 📷 Face placeholder / camera frame
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: isScanning
                    ? const CircularProgressIndicator(
                        color: Colors.blueAccent,
                        strokeWidth: 3,
                      )
                    : Icon(
                        Icons.face_retouching_natural,
                        size: 120,
                        color: AppColors.primaryBlue,
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // 🟦 Scan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning ? null : _startScan,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  isScanning ? 'Scanning...' : 'Scan Now',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🧾 Result Section
            if (isSuspicious != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSuspicious! ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSuspicious! ? Colors.redAccent : Colors.green,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isSuspicious!
                          ? Icons.warning_amber_rounded
                          : Icons.verified_user,
                      color: isSuspicious! ? Colors.redAccent : Colors.green,
                      size: 70,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSuspicious!
                          ? 'Suspicious Face Detected!'
                          : 'Face Verified Safely!',
                      style: TextStyle(
                        color:
                            isSuspicious! ? Colors.redAccent : Colors.green[800],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSuspicious!
                          ? 'This person may not match the registered identity.'
                          : 'No suspicious or fake face detected.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.greyText),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

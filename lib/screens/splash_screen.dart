import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🛡️ Logo placeholder
              Image.asset(
                'assets/logo.png',
                  height: 120,
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'FraudShield',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 10),

              // Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Think it might be a scam? Check it instantly with FraudShield.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // 🟦 Tap to Start button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Tap to Start',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

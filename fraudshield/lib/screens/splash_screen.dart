import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'login_screen.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Shimmer Controller
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    
    // Appearance Animation
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _appearController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    // Shimmer Animation (Light Sweep)
    _shimmerController = AnimationController(
    vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: false);

    _appearController.forward();
    
    // Auto-navigate after delay (since no button is allowed)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy Base
      body: Stack(
        children: [
          // 1. Background Layer
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F172A), // Dark Navy
                    const Color(0xFF1E293B), // Slightly lighter Slate
                  ],
                ),
              ),
            ),
          ),

          // 2. Subtle Radial Glow (Behind Logo)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    radius: 0.7,
                    center: Alignment.center,
                  ),
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with Shimmer/Sweep Effect
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.4), // The shine
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: [
                                  _shimmerController.value - 0.3,
                                  _shimmerController.value,
                                  _shimmerController.value + 0.3,
                                ],
                                transform: const GradientRotation(math.pi / 4), // Diagonal sweep
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child: child,
                          );
                        },
                        child: const AppLogo(size: 100),
                      ),
                      
                      const SizedBox(height: 32),

                      // Brand Name
                      Text(
                        'FraudShield',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          fontSize: 32, // Bold and Prominent
                          fontFamily: 'Inter', // Or system default sans-serif
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Protecting You From Digital Fraud',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 4. Footer / Version (Optional, subtle)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Text(
                  'Powered by AI Security',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

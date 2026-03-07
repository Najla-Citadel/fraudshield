// lib/screens/awareness_tips_screen.dart
import 'package:flutter/material.dart';
import '../widgets/glass_surface.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/layouts/screen_scaffold.dart';

class AwarenessTipsScreen extends StatelessWidget {
  const AwarenessTipsScreen({super.key});

  // 🧠 Tips data
  final List<Map<String, String>> tips = const [
    {
      'image': 'assets/images/tip1.png',
      'title': 'Never share your OTP',
      'desc':
          'Banks or authorities will never ask for your one-time password. Keep it private at all times.'
    },
    {
      'image': 'assets/images/tip2.png',
      'title': 'Avoid clicking unknown links',
      'desc':
          'Scammers often send fake links to steal your personal info. Verify URLs before clicking.'
    },
    {
      'image': 'assets/images/tip3.png',
      'title': 'Use strong passwords',
      'desc':
          'Create unique passwords with numbers, symbols, and mixed case letters for every account.'
    },
    {
      'image': 'assets/images/tip4.png',
      'title': 'Be cautious of calls from strangers',
      'desc':
          'Never give out your IC or banking details over the phone to unknown callers.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Awareness & Tips',
      body: Column(
        children: [
          // 🔷 HEADER SECTION
          Padding(
            padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xl, DesignTokens.spacing.xl, DesignTokens.spacing.xl, DesignTokens.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: DesignTokens.colors.primary, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Must-Know Security Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: DesignTokens.colors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn how to protect yourself from scams and fraud.',
                  style: TextStyle(
                    color: DesignTokens.colors.textLight.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
  
          // 🔽 CONTENT
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(DesignTokens.spacing.lg, DesignTokens.spacing.md, DesignTokens.spacing.lg, DesignTokens.spacing.xxl),
                itemCount: tips.length,
                itemBuilder: (context, index) {
                  final tip = tips[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: GlassSurface(
                            padding: EdgeInsets.zero,
                            borderRadius: DesignTokens.radii.lg,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🖼 IMAGE
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(DesignTokens.radii.lg),
                                  ),
                                  child: Image.asset(
                                    tip['image']!,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 160,
                                        color: DesignTokens.colors.surfaceDark,
                                        child: Center(
                                          child: Icon(Icons.image_not_supported, 
                                            color: DesignTokens.colors.textLight.withValues(alpha: 0.3), size: 40),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      
                                // 📄 CONTENT
                                Padding(
                                  padding: EdgeInsets.fromLTRB(DesignTokens.spacing.lg, DesignTokens.spacing.lg, DesignTokens.spacing.lg, 18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tip['title']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        tip['desc']!,
                                        style: TextStyle(
                                          color: DesignTokens.colors.textLight.withValues(alpha: 0.7),
                                          height: 1.4,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

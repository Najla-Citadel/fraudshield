// lib/screens/awareness_tips_screen.dart
import 'package:flutter/material.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/animated_background.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    final theme = Theme.of(context);
    
    return AnimatedBackground(
      child: AdaptiveScaffold(
        title: 'Awareness & Tips',
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // 🔷 HEADER SECTION
            GlassSurface(
              borderRadius: 0, // Header style
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Must-Know Security Tips',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn how to protect yourself from scams and fraud.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
  
            // 🔽 CONTENT
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                              borderRadius: 22,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🖼 IMAGE
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(22),
                                    ),
                                    child: Image.asset(
                                      tip['image']!,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 160,
                                          color: theme.colorScheme.surfaceVariant,
                                          child: Center(
                                            child: Icon(Icons.image_not_supported, 
                                              color: theme.colorScheme.onSurfaceVariant, size: 40),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        
                                  // 📄 CONTENT
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tip['title']!,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          tip['desc']!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            height: 1.4,
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
      ),
    );
  }
}

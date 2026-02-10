// lib/screens/awareness_tips_screen.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AwarenessTipsScreen extends StatelessWidget {
  const AwarenessTipsScreen({super.key});

  // 🧠 Tips data (UNCHANGED CONTENT)
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
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Awareness & Tips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔷 HEADER SECTION (NEW)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Must-Know Security Tips',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Learn how to protect yourself from scams and fraud.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 🔽 CONTENT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return _TipCard(
                  image: tip['image']!,
                  title: tip['title']!,
                  desc: tip['desc']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////
/// TIP CARD (NEW MODERN CARD)
////////////////////////////////////////////////////////////////

class _TipCard extends StatelessWidget {
  final String image;
  final String title;
  final String desc;

  const _TipCard({
    required this.image,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            child: Image.asset(
              image,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),

          // 📄 CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

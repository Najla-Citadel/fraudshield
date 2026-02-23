import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CommunityMapCard extends StatelessWidget {
  const CommunityMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Darker Navy
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/scam-map'),
        child: Stack(
          children: [
          // 1. Map Background (Placeholder or Image)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/map_preview.png', // Ensure this asset exists or use a placeholder container
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.map, color: Colors.white24, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Active clusters detected in Klang Valley',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 4. Floating Report Button (Overhanging)

        ],
      ),
    ),
  );
}
}

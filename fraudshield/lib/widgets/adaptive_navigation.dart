import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';

class AdaptiveNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const AdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Check platform using Theme context for better testing support
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIos) {
      // iOS: Glassmorphism Tab Bar
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CupertinoTabBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
            backgroundColor: Theme.of(context).cardColor.withOpacity(0.8),
            activeColor: Theme.of(context).primaryColor,
            inactiveColor: Colors.grey,
            iconSize: 28,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
      );
    } else {
      // Android: Material 3 NavigationBar
      return NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          backgroundColor: Theme.of(context).cardColor,
          elevation: 2,
          destinations: items.map((item) {
            return NavigationDestination(
              icon: item.icon,
              selectedIcon: item.activeIcon ?? item.icon,
              label: item.label ?? '',
            );
          }).toList(),
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<SettingsTile> items;
  final EdgeInsetsGeometry? margin;

  const SettingsGroup({
    super.key,
    this.title,
    required this.items,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
<<<<<<< HEAD
                  color: Colors.white.withOpacity(0.5),
=======
                  color: Colors.white.withValues(alpha: 0.5),
>>>>>>> dev-ui2
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
<<<<<<< HEAD
              border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
<<<<<<< HEAD
                      color: Colors.white.withOpacity(0.05),
=======
                      color: Colors.white.withValues(alpha: 0.05),
>>>>>>> dev-ui2
                      indent: 56, // Align with text start
                    ),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
    this.subtitle,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.redAccent : (iconColor ?? Colors.blueAccent);
    final bgColor = isDestructive 
<<<<<<< HEAD
        ? Colors.redAccent.withOpacity(0.1) 
        : (iconBgColor ?? color.withOpacity(0.1));
=======
        ? Colors.redAccent.withValues(alpha: 0.1) 
        : (iconBgColor ?? color.withValues(alpha: 0.1));
>>>>>>> dev-ui2

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // For ripple effect if needed
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? Colors.redAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
<<<<<<< HEAD
                          color: Colors.white.withOpacity(0.5),
=======
                          color: Colors.white.withValues(alpha: 0.5),
>>>>>>> dev-ui2
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
<<<<<<< HEAD
                  color: Colors.white.withOpacity(0.2),
=======
                  color: Colors.white.withValues(alpha: 0.2),
>>>>>>> dev-ui2
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

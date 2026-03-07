import 'package:flutter/material.dart';
import 'package:fraudshield/design_system/tokens/design_tokens.dart';
import 'package:fraudshield/design_system/components/app_divider.dart';

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
    final colors = DesignTokens.colors;
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: DesignTokens.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.only(left: DesignTokens.spacing.lg, bottom: DesignTokens.spacing.sm),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  color: colors.textLight.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: colors.glassDark,
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
              border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    AppDivider(
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
    final colors = DesignTokens.colors;
    final color = isDestructive ? colors.error : (iconColor ?? colors.info);
    final bgColor = isDestructive 
        ? colors.error.withValues(alpha: 0.1) 
        : (iconBgColor ?? color.withValues(alpha: 0.1));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radii.md),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? colors.error : colors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: colors.textLight.withValues(alpha: 0.5),
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
                  color: colors.textLight.withValues(alpha: 0.2),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

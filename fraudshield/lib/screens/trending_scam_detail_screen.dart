import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../design_system/layouts/screen_scaffold.dart';
import '../models/trending_scam.dart';

class TrendingScamDetailScreen extends StatelessWidget {
  final TrendingScam scam;

  const TrendingScamDetailScreen({super.key, required this.scam});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'THREAT INTEL',
      actions: [
        IconButton(
          icon: Icon(LucideIcons.share2, color: Colors.white, size: 20),
          onPressed: () {},
        ),
      ],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacing.xl,
              DesignTokens.spacing.xl,
              DesignTokens.spacing.xl,
              120, // Padding for bottom bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 24),
                _buildDescriptionCard(),
                if (scam.example != null) ...[
                  SizedBox(height: 24),
                  _buildVisualExample(),
                ],
                if (scam.safetyTips.isNotEmpty) ...[
                  SizedBox(height: 24),
                  _buildSafetyTips(),
                ],
                SizedBox(height: 48), // Bottom safe space
              ],
            ),
          ),
          // Sticky Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacing.xl,
                DesignTokens.spacing.lg,
                DesignTokens.spacing.xl,
                DesignTokens.spacing.xl + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF0F172A).withOpacity(0.95), // Slate 900
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: AppButton(
                onPressed: () {},
                label: 'Share Warning to Family',
                icon: LucideIcons.shieldAlert,
                variant: AppButtonVariant.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scam.badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
                border: Border.all(color: scam.badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                scam.badgeText,
                style: TextStyle(
                  color: scam.badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              scam.timestamp,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          scam.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignTokens.spacing.xl),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE THREAT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            scam.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.smartphone, color: Colors.white.withOpacity(0.7), size: 18),
            SizedBox(width: 8),
            Text(
              'Hook Example',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(DesignTokens.spacing.xl),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                radius: 18,
                child: Icon(LucideIcons.user, size: 20, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacing.md),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B), // Slate 800
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scam.example!.sender,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4, fontFamily: 'Inter'),
                          children: [
                            TextSpan(text: scam.example!.message),
                            TextSpan(
                              text: scam.example!.link,
                              style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: DesignTokens.colors.accentGreen, size: 18),
            SizedBox(width: 8),
            Text(
              'How to Stay Safe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(DesignTokens.spacing.lg),
          decoration: BoxDecoration(
            color: DesignTokens.colors.accentGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
            border: Border.all(color: DesignTokens.colors.accentGreen.withOpacity(0.1)),
          ),
          child: Column(
            children: scam.safetyTips.map((tip) {
              return Padding(
                padding: EdgeInsets.only(bottom: tip == scam.safetyTips.last ? 0 : 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: DesignTokens.colors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

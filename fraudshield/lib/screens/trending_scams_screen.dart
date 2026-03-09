import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../design_system/tokens/design_tokens.dart';
import '../design_system/components/app_button.dart';
import '../models/trending_scam.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/error_state.dart';
import 'trending_scam_detail_screen.dart';

class TrendingScamsScreen extends StatefulWidget {
  const TrendingScamsScreen({super.key});

  @override
  State<TrendingScamsScreen> createState() => _TrendingScamsScreenState();
}

class _TrendingScamsScreenState extends State<TrendingScamsScreen> {
  List<TrendingScam> _scams = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Recent', 'Near Me', 'Financial'];

  @override
  void initState() {
    super.initState();
    _fetchTrendingScams();
  }

  Future<void> _fetchTrendingScams() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final scams = await ApiService.instance.getTrendingScams();
      
      if (mounted) {
        setState(() {
          _scams = scams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  DesignTokens.colors.backgroundDark,
                  Color(0xFF1E3A8A), // Blue 900
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterChips(),
                Expanded(
                  child: _isLoading 
                    ? _buildLoadingState() 
                    : _errorMessage != null
                      ? ErrorState(onRetry: _fetchTrendingScams, message: _errorMessage!)
                      : _buildScamList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(DesignTokens.spacing.lg),
      itemCount: 4,
      itemBuilder: (context, index) => SkeletonCard(
        height: 200,
        margin: EdgeInsets.only(bottom: DesignTokens.spacing.lg),
      ),
    );
  }

  Widget _buildScamList() {
    return AnimationLimiter(
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(DesignTokens.spacing.lg, DesignTokens.spacing.xl, DesignTokens.spacing.lg, 100),
        itemCount: _scams.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _ScamCard(
                  scam: _scams[index],
                  onToggleExpand: () {
                    setState(() {
                      _scams[index].isExpanded = !_scams[index].isExpanded;
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(DesignTokens.spacing.xl, DesignTokens.spacing.xl, DesignTokens.spacing.xl, DesignTokens.spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trending Scams',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(LucideIcons.slidersHorizontal, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xFF1E293B), // Slate 800
          borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search scam types...',
            hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
            prefixIcon: Icon(LucideIcons.search, color: Color(0xFF9CA3AF), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.lg, vertical: DesignTokens.spacing.md),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 70, // Ample space for padding
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.xl, vertical: DesignTokens.spacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? DesignTokens.colors.accentGreen : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radii.lg),
                border: Border.all(
                  color: isSelected ? DesignTokens.colors.accentGreen : Colors.white.withOpacity(0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: DesignTokens.colors.accentGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScamCard extends StatelessWidget {
  final TrendingScam scam;
  final VoidCallback onToggleExpand;

  const _ScamCard({required this.scam, required this.onToggleExpand});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(DesignTokens.spacing.xl),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B), // Slate 800
          borderRadius: BorderRadius.circular(DesignTokens.radii.xl),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: DesignTokens.shadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // shrink to fit contents
          children: [
            // Top Bar: Badge & Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Align(alignment: Alignment.centerLeft, child: _buildBadge(scam.badgeText, scam.badgeColor))),
                SizedBox(width: 8),
                Text(
                  scam.timestamp,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF), // slate-400
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(height: 16),
            // Title
            Text(
              scam.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            // Description
            Text(
              scam.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7), // slate-300
                height: 1.5,
              ),
            ),
            
            // Expanded Content (Animated Size)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: scam.isExpanded ? _buildExpandedContent(context) : SizedBox.shrink(),
            ),

            SizedBox(height: 20),
            // Bottom Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    // Add a small icon to the badge based on text
    IconData? iconData;
    if (text == 'HIGH GROWTH') iconData = LucideIcons.trendingUp;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: DesignTokens.spacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 12, color: color),
            SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        
        // Visual Example Box
        if (scam.example != null) ...[
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              color: Color(0xFF0F172A), // Slate 900
              borderRadius: BorderRadius.circular(DesignTokens.radii.md),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'VISUAL EXAMPLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      radius: 16,
                      child: Icon(LucideIcons.user, size: 18, color: Colors.white),
                    ),
                    SizedBox(width: 12),
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
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.4, fontFamily: 'Inter'),
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
              ],
            ),
          ),
          SizedBox(height: 24),
        ],

        // How to Stay Safe
        if (scam.safetyTips.isNotEmpty) ...[
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, color: DesignTokens.colors.accentGreen, size: 20),
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
          ...scam.safetyTips.map((tip) => Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spacing.md, left: DesignTokens.spacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
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
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (scam.isExpanded) {
      // Expanded Buttons (Report Similar & Share)
      return Row(
        children: [
          Expanded(
            child: AppButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrendingScamDetailScreen(scam: scam)),
                );
              },
              icon: LucideIcons.flag,
              label: 'View Full Intel',
              variant: AppButtonVariant.primary,
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: AppButton(
              onPressed: () {},
              label: '', // empty label for icon-only button
              icon: LucideIcons.share2,
              variant: AppButtonVariant.secondary,
            ),
          ),
        ],
      );
    } else {
      // Collapsed Buttons (View Details & Share)
      return Row(
        children: [
          Expanded(
            child: AppButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrendingScamDetailScreen(scam: scam)),
                );
              },
              label: 'View Details',
              icon: LucideIcons.eye,
              variant: AppButtonVariant.secondary,
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: AppButton(
              onPressed: () {},
              label: '',
              icon: LucideIcons.share2,
              variant: AppButtonVariant.secondary,
            ),
          ),
        ],
      );
    }
  }
}

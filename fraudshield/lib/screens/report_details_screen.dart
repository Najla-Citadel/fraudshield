import 'package:flutter/material.dart';
import '../design_system/components/app_back_button.dart';
import 'dart:ui';
import '../design_system/tokens/design_tokens.dart';
import '../services/api_service.dart';
import '../design_system/components/app_loading_indicator.dart';
import '../design_system/components/app_snackbar.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailsScreen({super.key, required this.report});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments =
          await ApiService.instance.getComments(widget.report['id']);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ApiService.instance.submitComment(
        reportId: widget.report['id'],
        text: text,
      );
      _commentController.clear();
      await _fetchComments();
    } catch (e) {
      AppSnackBar.showError(context, 'Failed to post comment: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = widget.report['status'] == 'VERIFIED';

    return Scaffold(
      backgroundColor: DesignTokens.colors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'REPORT DETAILS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: DesignTokens.colors.textLight.withOpacity(0.7),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const AppBackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded,
                color: DesignTokens.colors.textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.report['category'] ?? 'Scam Report',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: DesignTokens.colors.textLight,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isVerified)
                  Container(
                    margin: EdgeInsets.only(left: 12, top: 4),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.colors.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: DesignTokens.colors.accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: DesignTokens.colors.accentGreen, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: DesignTokens.colors.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 16,
                    color: DesignTokens.colors.textLight.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'Reported ${_getTimeAgo(widget.report['createdAt'])}',
                  style: TextStyle(
                      color: DesignTokens.colors.textLight.withOpacity(0.7),
                      fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: DesignTokens.colors.textLight.withOpacity(0.3),
                        shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.report['location'] ?? 'Petaling Jaya',
                    style: TextStyle(
                        color: DesignTokens.colors.textLight.withOpacity(0.7),
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Scam Source Card
            const Text('SCAM SOURCE',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildSourceCard(widget.report),

            const SizedBox(height: 24),

            // 3. Message Content
            const Text('MESSAGE CONTENT',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                '"${widget.report['description'] ?? 'No content available.'}"',
                style: TextStyle(
                  color: DesignTokens.colors.textLight,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. AI Risk Analysis
            Row(
              children: [
                Icon(Icons.psychology, color: DesignTokens.colors.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('AI RISK ANALYSIS',
                    style: TextStyle(
                        color: DesignTokens.colors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignTokens.colors.accentGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: DesignTokens.colors.accentGreen.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  ..._buildRiskPoints(widget.report)
                      .asMap()
                      .entries
                      .map((entry) {
                    return Column(
                      children: [
                        if (entry.key > 0) const SizedBox(height: 16),
                        _riskItem(entry.value['title']!, entry.value['desc']!),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Actions
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: DesignTokens.colors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: DesignTokens.colors.accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block_rounded,
                        color: DesignTokens.colors.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Stay Safe: Block This Number',
                      style: TextStyle(
                        color: DesignTokens.colors.accentGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 6. Comments Section (New for Phase 3)
            Row(
              children: [
                Icon(Icons.forum_rounded,
                    color: DesignTokens.colors.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('COMMUNITY DISCUSSION',
                    style: TextStyle(
                        color: DesignTokens.colors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const Spacer(),
                Text('${_comments.length} comments',
                    style: TextStyle(
                        color: DesignTokens.colors.textLight.withOpacity(0.5),
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCommentSection(),

            const SizedBox(height: 32),

            // 7. Screenshots (Blurred)
            Row(
              children: [
                Expanded(child: _screenshotPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _screenshotPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _screenshotPlaceholder()),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Screenshots are anonymized to protect user privacy.',
                  style: TextStyle(
                      color: DesignTokens.colors.textLight.withOpacity(0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      children: [
        // Comment Input
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF162032),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 14,
                backgroundColor: DesignTokens.colors.accentGreen,
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style:
                      TextStyle(color: DesignTokens.colors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(
                        color: DesignTokens.colors.textLight.withValues(alpha: 0.3),
                        fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingIndicator(
                            color: DesignTokens.colors.accentGreen, size: 20))
                    : Icon(Icons.send_rounded,
                        color: DesignTokens.colors.accentGreen, size: 20),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Comments List
        if (_isLoadingComments)
          Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child:
                      AppLoadingIndicator.center(color: DesignTokens.colors.accentGreen)))
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: DesignTokens.colors.textLight.withValues(alpha: 0.1),
                    size: 48),
                const SizedBox(height: 12),
                Text('No comments yet. Be the first to discuss!',
                    style: TextStyle(
                        color: DesignTokens.colors.textLight.withValues(alpha: 0.3),
                        fontSize: 13)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final userData = comment['user'] ?? {};

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      (userData['fullName'] ?? '?').substring(0, 1),
                      style: TextStyle(
                          color: DesignTokens.colors.textLight, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userData['fullName'] ?? 'Anonymous User',
                              style: TextStyle(
                                  color: DesignTokens.colors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeAgo(comment['createdAt']),
                               style: TextStyle(
                                  color: DesignTokens.colors.textLight
                                      .withValues(alpha: 0.3),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            comment['text'] ?? '',
                            style: TextStyle(
                                color:
                                    DesignTokens.colors.textLight.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  /// Builds the source card based on report type (Phone / Message / Document / Others)
  Widget _buildSourceCard(Map<String, dynamic> report) {
    final type = report['type'] ?? 'Message';
    final target = report['target'] as String? ?? '';

    final IconData icon;
    final String label;
    final String sublabel;

    switch (type) {
      case 'Phone':
        icon = Icons.phone_rounded;
        label = 'Call from $target';
        sublabel = 'Malaysia Mobile Network';
        break;
      case 'Document':
        icon = Icons.description_rounded;
        label = 'Document: ${target.isNotEmpty ? target : "Attached file"}';
        sublabel = 'Uploaded evidence file';
        break;
      case 'Message':
        icon = Icons.sms_rounded;
        label = target.isNotEmpty ? 'SMS from $target' : 'Suspicious message';
        sublabel = 'Malaysia Mobile Network';
        break;
      default:
        icon = Icons.warning_amber_rounded;
        label = target.isNotEmpty ? target : 'Other scam source';
        sublabel = 'Reported by community';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      color: DesignTokens.colors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                      color: DesignTokens.colors.textLight.withValues(alpha: 0.5),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generates dynamic AI risk analysis bullets from report fields
  List<Map<String, String>> _buildRiskPoints(Map<String, dynamic> report) {
    final points = <Map<String, String>>[];
    final category = (report['category'] ?? '').toString().toLowerCase();
    final type = (report['type'] ?? '').toString();
    final count = (report['_count']?['verifications'] ?? 0) as int;
    final description = (report['description'] ?? '').toString().toLowerCase();

    // Category-level signal
    if (category.contains('phishing') || category.contains('wallet')) {
      points.add({
        'title': 'Sense of Urgency',
        'desc':
            'Phishing messages often claim accounts are suspended to pressure victims into acting fast.',
      });
      if (description.contains('link') ||
          description.contains('url') ||
          description.contains('bit.ly')) {
        points.add({
          'title': 'Suspicious Link',
          'desc':
              'URL shortener or unofficial domain used to mask a phishing site.',
        });
      }
    } else if (category.contains('investment')) {
      points.add({
        'title': 'Unrealistic Returns',
        'desc':
            '"Guaranteed" high-return schemes are always red flags. Check BNM Alert List before investing.',
      });
      if (description.contains('telegram') ||
          description.contains('whatsapp') ||
          description.contains('group')) {
        points.add({
          'title': 'Social Media Pressure',
          'desc':
              'Scammers often use closed group chats to fabricate testimonials and urgency.',
        });
      }
    } else if (category.contains('courier') || category.contains('delivery')) {
      points.add({
        'title': 'Impersonation Tactic',
        'desc':
            'Official couriers never request bank details or fees via phone call.',
      });
      points.add({
        'title': 'Illegal Parcel Threat',
        'desc':
            'Threatening legal action over a parcel is a known social engineering tactic.',
      });
    } else if (category.contains('love') || category.contains('romance')) {
      points.add({
        'title': 'Emotional Manipulation',
        'desc':
            'Romance scammers build trust over time before making financial requests.',
      });
    } else if (category.contains('job')) {
      points.add({
        'title': 'Advance Fee',
        'desc':
            'Legitimate employers never ask you to pay upfront to secure a job offer.',
      });
    }

    // Source type signal
    if (type == 'Phone') {
      points.add({
        'title': 'Sender ID',
        'desc':
            'Unknown mobile number used instead of an official registered shortcode.',
      });
    }

    // Community verification signal
    if (count > 3) {
      points.add({
        'title': 'Community Flagged',
        'desc':
            '$count users have independently reported this as a scam — treat with high caution.',
      });
    }

    // Fallback
    if (points.isEmpty) {
      points.add({
        'title': 'Unverified Source',
        'desc':
            'Always verify the source before taking any action on unsolicited messages.',
      });
    }

    return points;
  }

  Widget _riskItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFF87171), // Red
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(height: 1.5, fontSize: 14),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                      color: DesignTokens.colors.textLight, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                      color: DesignTokens.colors.textLight.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _screenshotPlaceholder() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Mock Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image,
                      color: Colors.white.withOpacity(0.2), size: 32),
                ],
              ),
              // Blur it
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),
              Center(
                child: Icon(Icons.visibility_off,
                    color: Colors.white.withOpacity(0.5), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '2 hours ago';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '2 hours ago';
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/colors.dart';
<<<<<<< HEAD
import '../widgets/adaptive_button.dart';
=======
>>>>>>> dev-ui2
import '../services/api_service.dart';

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
<<<<<<< HEAD
      final comments = await ApiService.instance.getComments(widget.report['id']);
=======
      final comments =
          await ApiService.instance.getComments(widget.report['id']);
>>>>>>> dev-ui2
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = widget.report['status'] == 'VERIFIED';

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'REPORT DETAILS',
          style: theme.textTheme.labelMedium?.copyWith(
<<<<<<< HEAD
            color: AppColors.textLight.withOpacity(0.7),
=======
            color: AppColors.textLight.withValues(alpha: 0.7),
>>>>>>> dev-ui2
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
<<<<<<< HEAD
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textLight, size: 20),
=======
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textLight, size: 20),
>>>>>>> dev-ui2
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textLight),
=======
            icon: const Icon(Icons.more_horiz_rounded,
                color: AppColors.textLight),
>>>>>>> dev-ui2
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
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                if (isVerified)
                  Container(
                    margin: const EdgeInsets.only(left: 12, top: 4),
<<<<<<< HEAD
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
=======
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accentGreen.withValues(alpha: 0.3)),
>>>>>>> dev-ui2
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
<<<<<<< HEAD
                        Icon(Icons.verified_user_rounded, color: AppColors.accentGreen, size: 14),
=======
                        Icon(Icons.verified_user_rounded,
                            color: AppColors.accentGreen, size: 14),
>>>>>>> dev-ui2
                        SizedBox(width: 6),
                        Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: AppColors.accentGreen,
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
<<<<<<< HEAD
                Icon(Icons.access_time_rounded, size: 16, color: AppColors.textLight.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'Reported ${_getTimeAgo(widget.report['createdAt'])}',
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(width: 4, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withOpacity(0.3), shape: BoxShape.circle)),
=======
                Icon(Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.textLight.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'Reported ${_getTimeAgo(widget.report['createdAt'])}',
                  style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: 0.3),
                        shape: BoxShape.circle)),
>>>>>>> dev-ui2
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.report['location'] ?? 'Petaling Jaya',
<<<<<<< HEAD
                    style: TextStyle(color: AppColors.textLight.withOpacity(0.7), fontSize: 13),
=======
                    style: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.7),
                        fontSize: 13),
>>>>>>> dev-ui2
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Scam Source Card
<<<<<<< HEAD
            const Text('SCAM SOURCE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
=======
            const Text('SCAM SOURCE',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
>>>>>>> dev-ui2
            const SizedBox(height: 12),
            _buildSourceCard(widget.report),

            const SizedBox(height: 24),

            // 3. Message Content
<<<<<<< HEAD
            const Text('MESSAGE CONTENT', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
=======
            const Text('MESSAGE CONTENT',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
>>>>>>> dev-ui2
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF162032),
                borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
                border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
              ),
              child: Text(
                '"${widget.report['description'] ?? 'No content available.'}"',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

<<<<<<< HEAD
             // 4. AI Risk Analysis
=======
            // 4. AI Risk Analysis
>>>>>>> dev-ui2
            Row(
              children: const [
                Icon(Icons.psychology, color: AppColors.accentGreen, size: 20),
                SizedBox(width: 8),
<<<<<<< HEAD
                Text('AI RISK ANALYSIS', style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
=======
                Text('AI RISK ANALYSIS',
                    style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
>>>>>>> dev-ui2
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
<<<<<<< HEAD
                color: AppColors.accentGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  ..._buildRiskPoints(widget.report).asMap().entries.map((entry) {
=======
                color: AppColors.accentGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  ..._buildRiskPoints(widget.report)
                      .asMap()
                      .entries
                      .map((entry) {
>>>>>>> dev-ui2
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
<<<<<<< HEAD
            AdaptiveButton(
              text: 'Stay Safe: Block This Number',
              onPressed: () {},
              icon: const Icon(Icons.block_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 32),
            
            // 6. Comments Section (New for Phase 3)
            Row(
              children: [
                const Icon(Icons.forum_rounded, color: AppColors.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('COMMUNITY DISCUSSION', style: const TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const Spacer(),
                Text('${_comments.length} comments', style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 11)),
=======
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.block_rounded,
                        color: AppColors.accentGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Stay Safe: Block This Number',
                      style: TextStyle(
                        color: AppColors.accentGreen,
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
                const Icon(Icons.forum_rounded,
                    color: AppColors.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text('COMMUNITY DISCUSSION',
                    style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const Spacer(),
                Text('${_comments.length} comments',
                    style: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.5),
                        fontSize: 11)),
>>>>>>> dev-ui2
              ],
            ),
            const SizedBox(height: 16),
            _buildCommentSection(),

            const SizedBox(height: 32),
<<<<<<< HEAD
            
=======

>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
=======
                  style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
            border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accentGreen,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
<<<<<<< HEAD
                  style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
=======
                  style:
                      const TextStyle(color: AppColors.textLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.3),
                        fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
>>>>>>> dev-ui2
                  ),
                ),
              ),
              IconButton(
<<<<<<< HEAD
                icon: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreen))
                  : const Icon(Icons.send_rounded, color: AppColors.accentGreen, size: 20),
=======
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accentGreen))
                    : const Icon(Icons.send_rounded,
                        color: AppColors.accentGreen, size: 20),
>>>>>>> dev-ui2
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
<<<<<<< HEAD
        
        // Comments List
        if (_isLoadingComments)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.accentGreen)))
=======

        // Comments List
        if (_isLoadingComments)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      CircularProgressIndicator(color: AppColors.accentGreen)))
>>>>>>> dev-ui2
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
<<<<<<< HEAD
                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textLight.withOpacity(0.1), size: 48),
                const SizedBox(height: 12),
                Text('No comments yet. Be the first to discuss!', style: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 13)),
=======
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textLight.withValues(alpha: 0.1),
                    size: 48),
                const SizedBox(height: 12),
                Text('No comments yet. Be the first to discuss!',
                    style: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.3),
                        fontSize: 13)),
>>>>>>> dev-ui2
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
              final profile = userData['profile'] ?? {};
<<<<<<< HEAD
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    child: Text(
                      (userData['fullName'] ?? '?').substring(0, 1),
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
=======

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      (userData['fullName'] ?? '?').substring(0, 1),
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 12),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 13),
=======
                              style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
>>>>>>> dev-ui2
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getTimeAgo(comment['createdAt']),
<<<<<<< HEAD
                              style: TextStyle(color: AppColors.textLight.withOpacity(0.3), fontSize: 11),
=======
                              style: TextStyle(
                                  color: AppColors.textLight
                                      .withValues(alpha: 0.3),
                                  fontSize: 11),
>>>>>>> dev-ui2
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
<<<<<<< HEAD
                            color: Colors.white.withOpacity(0.03),
=======
                            color: Colors.white.withValues(alpha: 0.03),
>>>>>>> dev-ui2
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            comment['text'] ?? '',
<<<<<<< HEAD
                            style: TextStyle(color: AppColors.textLight.withOpacity(0.8), fontSize: 14, height: 1.4),
=======
                            style: TextStyle(
                                color:
                                    AppColors.textLight.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.4),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        border: Border.all(color: Colors.white.withOpacity(0.05)),
=======
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
>>>>>>> dev-ui2
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
<<<<<<< HEAD
              color: const Color(0xFF1E3A8A).withOpacity(0.4),
=======
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16),
=======
                  style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
>>>>>>> dev-ui2
                ),
                const SizedBox(height: 4),
                Text(
                  sublabel,
<<<<<<< HEAD
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.5), fontSize: 13),
=======
                  style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.5),
                      fontSize: 13),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
        'desc': 'Phishing messages often claim accounts are suspended to pressure victims into acting fast.',
      });
      if (description.contains('link') || description.contains('url') || description.contains('bit.ly')) {
        points.add({
          'title': 'Suspicious Link',
          'desc': 'URL shortener or unofficial domain used to mask a phishing site.',
=======
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
>>>>>>> dev-ui2
        });
      }
    } else if (category.contains('investment')) {
      points.add({
        'title': 'Unrealistic Returns',
<<<<<<< HEAD
        'desc': '"Guaranteed" high-return schemes are always red flags. Check BNM Alert List before investing.',
      });
      if (description.contains('telegram') || description.contains('whatsapp') || description.contains('group')) {
        points.add({
          'title': 'Social Media Pressure',
          'desc': 'Scammers often use closed group chats to fabricate testimonials and urgency.',
=======
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
>>>>>>> dev-ui2
        });
      }
    } else if (category.contains('courier') || category.contains('delivery')) {
      points.add({
        'title': 'Impersonation Tactic',
<<<<<<< HEAD
        'desc': 'Official couriers never request bank details or fees via phone call.',
      });
      points.add({
        'title': 'Illegal Parcel Threat',
        'desc': 'Threatening legal action over a parcel is a known social engineering tactic.',
=======
        'desc':
            'Official couriers never request bank details or fees via phone call.',
      });
      points.add({
        'title': 'Illegal Parcel Threat',
        'desc':
            'Threatening legal action over a parcel is a known social engineering tactic.',
>>>>>>> dev-ui2
      });
    } else if (category.contains('love') || category.contains('romance')) {
      points.add({
        'title': 'Emotional Manipulation',
<<<<<<< HEAD
        'desc': 'Romance scammers build trust over time before making financial requests.',
=======
        'desc':
            'Romance scammers build trust over time before making financial requests.',
>>>>>>> dev-ui2
      });
    } else if (category.contains('job')) {
      points.add({
        'title': 'Advance Fee',
<<<<<<< HEAD
        'desc': 'Legitimate employers never ask you to pay upfront to secure a job offer.',
=======
        'desc':
            'Legitimate employers never ask you to pay upfront to secure a job offer.',
>>>>>>> dev-ui2
      });
    }

    // Source type signal
    if (type == 'Phone') {
      points.add({
        'title': 'Sender ID',
<<<<<<< HEAD
        'desc': 'Unknown mobile number used instead of an official registered shortcode.',
=======
        'desc':
            'Unknown mobile number used instead of an official registered shortcode.',
>>>>>>> dev-ui2
      });
    }

    // Community verification signal
    if (count > 3) {
      points.add({
        'title': 'Community Flagged',
<<<<<<< HEAD
        'desc': '$count users have independently reported this as a scam — treat with high caution.',
=======
        'desc':
            '$count users have independently reported this as a scam — treat with high caution.',
>>>>>>> dev-ui2
      });
    }

    // Fallback
    if (points.isEmpty) {
      points.add({
        'title': 'Unverified Source',
<<<<<<< HEAD
        'desc': 'Always verify the source before taking any action on unsolicited messages.',
=======
        'desc':
            'Always verify the source before taking any action on unsolicited messages.',
>>>>>>> dev-ui2
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
            decoration: const BoxDecoration(
              color: Color(0xFFF87171), // Red
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
<<<<<<< HEAD
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: AppColors.textLight.withOpacity(0.8)),
=======
                  style: const TextStyle(
                      color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.8)),
>>>>>>> dev-ui2
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
<<<<<<< HEAD
      aspectRatio: 3/4,
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
                   Icon(Icons.image, color: Colors.white.withOpacity(0.2), size: 32),
                 ],
               ),
               // Blur it
               BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                 child: Container(color: Colors.black.withOpacity(0.1)),
               ),
               Center(
                 child: Icon(Icons.visibility_off, color: Colors.white.withOpacity(0.5), size: 24),
               ),
             ],
           ),
=======
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
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
                      color: Colors.white.withValues(alpha: 0.2), size: 32),
                ],
              ),
              // Blur it
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
              Center(
                child: Icon(Icons.visibility_off,
                    color: Colors.white.withValues(alpha: 0.5), size: 24),
              ),
            ],
          ),
>>>>>>> dev-ui2
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
<<<<<<< HEAD

=======
>>>>>>> dev-ui2

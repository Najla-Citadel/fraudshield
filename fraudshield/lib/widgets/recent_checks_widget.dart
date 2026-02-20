import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/recent_checks_service.dart';
import 'package:intl/intl.dart';

class RecentChecksWidget extends StatefulWidget {
  final Function(RecentCheckItem) onCheckSelected;

  const RecentChecksWidget({
    super.key,
    required this.onCheckSelected,
  });

  @override
  State<RecentChecksWidget> createState() => RecentChecksWidgetState();
}

class RecentChecksWidgetState extends State<RecentChecksWidget> {
  List<RecentCheckItem> _checks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => _isLoading = true);
    final checks = await RecentChecksService.getRecentChecks();
    if (mounted) {
      setState(() {
        _checks = checks;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    await RecentChecksService.clearHistory();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_checks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Checks',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.4),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _checks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _checks[index];
            return _buildCheckItem(item);
          },
        ),
      ],
    );
  }

  Widget _buildCheckItem(RecentCheckItem item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case 'Phone No':
      case 'Phone':
        icon = Icons.phone_outlined;
        color = Colors.blueAccent;
        break;
      case 'URL':
        icon = Icons.link;
        color = Colors.purpleAccent;
        break;
      case 'Bank Acc':
        icon = Icons.account_balance_outlined;
        color = Colors.orangeAccent;
        break;
      default:
        icon = Icons.search;
        color = Colors.grey;
    }

    // Format date: "2 mins ago", "Yesterday", etc.
    String timeAgo = '';
    final diff = DateTime.now().difference(item.timestamp);
    if (diff.inSeconds < 60) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo = DateFormat('MMM d').format(item.timestamp);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onCheckSelected(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.type,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.restore, 
                color: Colors.white.withOpacity(0.2), 
                size: 16
              ),
            ],
          ),
        ),
      ),
    );
  }
}

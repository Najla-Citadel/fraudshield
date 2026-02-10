import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/scam_card.dart';
import '../widgets/scam_map_view.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  bool _isMapMode = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Investment Scam',
    'Phishing Scam',
    'Job Scam',
    'Love Scam',
    'Fake Giveaway / Promo Scam',
  ];

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ApiService.instance.getPublicFeed();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching feed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _selectedCategory == 'All'
        ? _reports
        : _reports.where((r) => r['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Scam Feed'),
        actions: [
          IconButton(
            icon: Icon(_isMapMode ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _isMapMode = !_isMapMode),
            tooltip: _isMapMode ? 'Show List' : 'Show Map',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFeed,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: Colors.red,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.red : Colors.grey[300]!,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredReports.isEmpty
              ? const Center(child: Text('No reports in this category. Stay safe!'))
              : _isMapMode
                  ? ScamMapView(
                      reports: filteredReports,
                      onRefresh: _fetchFeed,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        return ScamCard(
                          report: filteredReports[index],
                          onVerify: _fetchFeed, // Refresh after verify
                        );
                      },
                    ),
    );
  }
}

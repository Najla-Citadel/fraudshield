import 'package:flutter/material.dart';
import '../design_system/components/app_button.dart';
import '../design_system/tokens/design_tokens.dart';

class SearchFilterModal extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;
  final int initialMinVerifications;
  final String initialSortBy;
  final Function(DateTime?, DateTime?, int, String) onApplyFilters;

  const SearchFilterModal({
    super.key,
    this.initialDateFrom,
    this.initialDateTo,
    this.initialMinVerifications = 0,
    this.initialSortBy = 'newest',
    required this.onApplyFilters,
  });

  @override
  State<SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends State<SearchFilterModal> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _minVerifications = 0;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    _minVerifications = widget.initialMinVerifications;
    _sortBy = widget.initialSortBy;
  }

  Future<void> _selectDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateFrom = picked);
    }
  }

  Future<void> _selectDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: _dateFrom ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateTo = picked);
    }
  }

  void _setQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      switch (filter) {
        case 'today':
          _dateFrom = DateTime(now.year, now.month, now.day);
          _dateTo = now;
          break;
        case 'week':
          _dateFrom = now.subtract(const Duration(days: 7));
          _dateTo = now;
          break;
        case 'month':
          _dateFrom = now.subtract(const Duration(days: 30));
          _dateTo = now;
          break;
        case 'all':
          _dateFrom = null;
          _dateTo = null;
          break;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _minVerifications = 0;
      _sortBy = 'newest';
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_dateFrom, _dateTo, _minVerifications, _sortBy);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Section
                  Text(
                    '📅 Date Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          label: 'From',
                          date: _dateFrom,
                          onTap: _selectDateFrom,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDateButton(
                          label: 'To',
                          date: _dateTo,
                          onTap: _selectDateTo,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Quick filters
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickFilterChip('Today', 'today'),
                      _buildQuickFilterChip('This Week', 'week'),
                      _buildQuickFilterChip('This Month', 'month'),
                      _buildQuickFilterChip('All Time', 'all'),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Verification Count Section
                  Text(
                    '✓ Minimum Verifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minVerifications.toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 10,
                          label: _minVerifications == 0
                              ? 'Any'
                              : _minVerifications.toString(),
                          onChanged: (value) {
                            setState(() => _minVerifications = value.toInt());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          _minVerifications == 0
                              ? 'Any'
                              : _minVerifications.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Sort By Section
                  Text(
                    '🔽 Sort By',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildSortOption('Newest First', 'newest'),
                  _buildSortOption('Most Verified', 'verified'),
                  _buildSortOption('Highest Trust Score', 'trust'),
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: EdgeInsets.all(DesignTokens.spacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: _clearFilters,
                    label: 'Clear All',
                    variant: AppButtonVariant.destructive,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    onPressed: _applyFilters,
                    label: 'Apply Filters',
                    variant: AppButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing.md, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(DesignTokens.radii.xs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                color: date != null ? Colors.black : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, String filter) {
    final isActive = () {
      if (filter == 'all') return _dateFrom == null && _dateTo == null;
      if (filter == 'today' && _dateFrom != null) {
        final now = DateTime.now();
        return _dateFrom!.day == now.day &&
            _dateFrom!.month == now.month &&
            _dateFrom!.year == now.year;
      }
      return false;
    }();

    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => _setQuickFilter(filter),
      selectedColor: Colors.red,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _sortBy = newValue);
        }
      },
      activeColor: Colors.red,
      contentPadding: EdgeInsets.zero,
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterData {
  final DateTime? from;
  final DateTime? to;
  final String? category;

  FilterData({this.from, this.to, this.category});
}

class FilterSheet extends StatefulWidget {
  final void Function(FilterData filterData) onApply;
  final FilterData? initialFilter;

  const FilterSheet({super.key, required this.onApply, this.initialFilter});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedCategory;

  final Color primaryBlue = const Color(0xFF007AFF);

  final List<String> _categories = [
    'water',
    'electricity',
    'roadwork',
    'transportation',
    'safety',
    'environment',
    'event',
    'general',
    'foodAndBeverage',
    'retailAndShops',
    'services',
    'health',
    'dealsAndOffers',
    'newInTheArea',
  ];

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFilter?.from;
    _toDate = widget.initialFilter?.to;
    _selectedCategory = widget.initialFilter?.category;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedCategory = null;
    });
  }

  void _applyFilters() {
    if (_fromDate != null && _toDate != null && _toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    widget.onApply(
      FilterData(from: _fromDate, to: _toDate, category: _selectedCategory),
    );
    Navigator.pop(context);
  }

  void _showCategoryPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem:
                          _selectedCategory != null
                              ? _categories.indexOf(_selectedCategory!)
                              : 0,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedCategory = _categories[index]);
                    },
                    children:
                        _categories.map((cat) {
                          final label = cat
                              .replaceAllMapped(
                                RegExp(r'([a-z])([A-Z])'),
                                (m) => '${m[1]} ${m[2]}',
                              )
                              .replaceFirstMapped(
                                RegExp(r'^[a-z]'),
                                (m) => m.group(0)!.toUpperCase(),
                              );
                          return Center(child: Text(label));
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd-MM-yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Filter by:',
              style: TextStyle(fontSize: 14, color: Color(0xFF555E67)),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label:
                      _fromDate != null
                          ? formatter.format(_fromDate!)
                          : 'From Date',
                  onTap: () => _pickDate(isFrom: true),
                  clear:
                      _fromDate != null
                          ? () => setState(() => _fromDate = null)
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label:
                      _toDate != null ? formatter.format(_toDate!) : 'To Date',
                  onTap: () => _pickDate(isFrom: false),
                  clear:
                      _toDate != null
                          ? () => setState(() => _toDate = null)
                          : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCategory != null
                          ? _selectedCategory!
                              .replaceAllMapped(
                                RegExp(r'([a-z])([A-Z])'),
                                (m) => '${m[1]} ${m[2]}',
                              )
                              .replaceFirstMapped(
                                RegExp(r'^[a-z]'),
                                (m) => m.group(0)!.toUpperCase(),
                              )
                          : 'Select Category',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Color(0xFFEEF1F4),
                    foregroundColor: primaryBlue,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Reset All',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
    VoidCallback? clear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (clear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: clear,
              ),
          ],
        ),
      ),
    );
  }
}

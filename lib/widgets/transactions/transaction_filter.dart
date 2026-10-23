import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../statistics/date_range_filter.dart';

class TransactionFilter extends StatelessWidget {
  final TextEditingController keywordController;
  final TransactionType? selectedType;
  final String? selectedCategory;
  final List<String> categories;
  final DateTime? startDate;
  final DateTime? endDate;

  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onClearKeyword;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final VoidCallback onReset;

  const TransactionFilter({
    super.key,
    required this.keywordController,
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.startDate,
    required this.endDate,
    required this.onKeywordChanged,
    required this.onClearKeyword,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: keywordController,
          decoration: InputDecoration(
            hintText: 'Nhập tên giao dịch...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Xóa từ khóa',
              icon: const Icon(Icons.clear),
              onPressed: onClearKeyword,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: onKeywordChanged,
        ),
        const SizedBox(height: 20),

        const Text(
          'Loại giao dịch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        SegmentedButton<TransactionType?>(
          segments: const [
            ButtonSegment<TransactionType?>(value: null, label: Text('Tất cả')),
            ButtonSegment<TransactionType?>(
              value: TransactionType.expense,
              label: Text('Chi tiêu'),
            ),
            ButtonSegment<TransactionType?>(
              value: TransactionType.income,
              label: Text('Thu nhập'),
            ),
          ],
          selected: {selectedType},
          onSelectionChanged: (selection) {
            onTypeChanged(selection.first);
          },
        ),
        const SizedBox(height: 20),

        const Text(
          'Danh mục',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        DropdownButtonFormField<String?>(
          initialValue: selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          hint: const Text('Tất cả danh mục'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tất cả danh mục'),
            ),
            ...categories.map(
              (category) => DropdownMenuItem<String?>(
                value: category,
                child: Text(category),
              ),
            ),
          ],
          onChanged: onCategoryChanged,
        ),

        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Đặt lại bộ lọc'),
        ),
        const SizedBox(height: 24),

        DateRangeFilter(
          startDate: startDate,
          endDate: endDate,
          onSelectStartDate: onSelectStartDate,
          onSelectEndDate: onSelectEndDate,
        ),
      ],
    );
  }
}

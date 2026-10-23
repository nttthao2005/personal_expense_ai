import 'package:flutter/material.dart';

import '../../../models/transaction.dart';

class TransactionFormFields extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;

  final TransactionType type;
  final String category;
  final DateTime date;
  final List<String> categories;

  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSelectDate;

  const TransactionFormFields({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.type,
    required this.category,
    required this.date,
    required this.categories,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loại giao dịch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Chi tiêu'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Thu nhập'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {type},
            onSelectionChanged: (selection) {
              onTypeChanged(selection.first);
            },
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Tên giao dịch',
              hintText: 'Ví dụ: Ăn trưa, tiền lương...',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên giao dịch';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Số tiền (VNĐ)',
              hintText: 'Ví dụ: 50000',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: '₫',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');

              if (amount == null || amount <= 0) {
                return 'Vui lòng nhập số tiền hợp lệ';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: 'Danh mục',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: categories.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onCategoryChanged,
          ),

          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: const Text('Ngày giao dịch'),
            subtitle: Text(
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onSelectDate,
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ghi chú (không bắt buộc)',
              hintText: 'Nhập nội dung bổ sung...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

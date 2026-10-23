import 'package:flutter/material.dart';

class ReceiptConfirmationForm extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final DateTime selectedDate;
  final bool isSaving;
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final TextEditingController recipientNameController;
  const ReceiptConfirmationForm({
    super.key,
    required this.descriptionController,
    required this.amountController,
    required this.selectedDate,
    required this.isSaving,
    required this.onPickDate,
    required this.recipientNameController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Xác nhận thông tin hóa đơn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Mô tả giao dịch',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: recipientNameController,
          decoration: const InputDecoration(
            labelText: 'Tên người nhận',
            hintText: 'Nhập tên nếu chưa nhận diện được',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Số tiền (VNĐ)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Ngày giao dịch',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}/'
                  '${selectedDate.month.toString().padLeft(2, '0')}/'
                  '${selectedDate.year}',
                ),
              ),
              TextButton(onPressed: onPickDate, child: const Text('Chọn ngày')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isSaving ? 'Đang lưu...' : 'Lưu giao dịch'),
          ),
        ),
      ],
    );
  }
}

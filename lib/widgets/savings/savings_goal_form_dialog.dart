import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/savings_goal.dart';

class SavingsGoalFormDialog extends StatefulWidget {
  final SavingsGoal? initialGoal;

  const SavingsGoalFormDialog({super.key, this.initialGoal});

  @override
  State<SavingsGoalFormDialog> createState() => _SavingsGoalFormDialogState();
}

class _SavingsGoalFormDialogState extends State<SavingsGoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();

  DateTime? _deadline;
  @override
  void initState() {
    super.initState();

    final goal = widget.initialGoal;

    if (goal != null) {
      _nameController.text = goal.name;
      _targetAmountController.text = goal.targetAmount.toStringAsFixed(0);
      _deadline = goal.deadline;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
      helpText: 'Chọn hạn hoàn thành',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _deadline = selectedDate;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetAmount = double.parse(_targetAmountController.text.trim());

    Navigator.of(context).pop(
      SavingsGoal(
        id: widget.initialGoal?.id,
        name: name,
        targetAmount: targetAmount,
        savedAmount: widget.initialGoal?.savedAmount ?? 0,
        createdAt: widget.initialGoal?.createdAt ?? DateTime.now(),
        deadline: _deadline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialGoal == null
            ? 'Tạo mục tiêu tiết kiệm'
            : 'Chỉnh sửa mục tiêu tiết kiệm',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên mục tiêu',
                  hintText: 'Ví dụ: Mua laptop',
                  prefixIcon: Icon(Icons.savings_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLength: 60,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên mục tiêu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Số tiền cần đạt (VNĐ)',
                  hintText: 'Ví dụ: 15000000',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');

                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Nhập số tiền lớn hơn 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _selectDeadline,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _deadline == null
                      ? 'Chọn hạn hoàn thành (không bắt buộc)'
                      : 'Hạn: ${DateFormat('dd/MM/yyyy').format(_deadline!)}',
                ),
              ),
              if (_deadline != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _deadline = null;
                    });
                  },
                  child: const Text('Bỏ hạn hoàn thành'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initialGoal == null ? 'Tạo mục tiêu' : 'Lưu thay đổi',
          ),
        ),
      ],
    );
  }
}

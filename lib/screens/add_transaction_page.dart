import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/transactions/form/transaction_form_fields.dart';

class AddTransactionPage extends StatefulWidget {
  final ExpenseTransaction? transaction;

  const AddTransactionPage({super.key, this.transaction});

  bool get isEditing => transaction != null;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = 'Ăn uống';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.note ?? '';

      _type = transaction.type;
      _category = transaction.category;
      _date = transaction.date;
    }
  }

  final List<String> _expenseCategories = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Học tập',
    'Hóa đơn',
    'Giải trí',
    'Khác',
  ];

  final List<String> _incomeCategories = [
    'Lương',
    'Thưởng',
    'Tiền được cho',
    'Đầu tư',
    'Khác',
  ];

  List<String> get _categories =>
      _type == TransactionType.expense ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày giao dịch',
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.trim());

      final transaction = ExpenseTransaction(
        id: widget.transaction?.id,
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        date: _date,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (widget.isEditing) {
        await DatabaseService.instance.updateTransaction(transaction);
      } else {
        await DatabaseService.instance.insertTransaction(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Đã cập nhật giao dịch thành công!'
                : 'Đã lưu giao dịch thành công!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu giao dịch: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionFormFields(
                formKey: _formKey,
                titleController: _titleController,
                amountController: _amountController,
                noteController: _noteController,
                type: _type,
                category: _category,
                date: _date,
                categories: _categories,
                onTypeChanged: (type) {
                  setState(() {
                    _type = type;
                    _category = _categories.first;
                  });
                },
                onCategoryChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
                onSelectDate: _selectDate,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTransaction,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Đang lưu...' : 'Lưu giao dịch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

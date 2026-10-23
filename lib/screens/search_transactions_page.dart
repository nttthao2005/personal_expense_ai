import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import 'add_transaction_page.dart';
import '../widgets/transactions/transaction_filter.dart';
import '../widgets/transactions/transaction_list_item.dart';

class SearchTransactionsPage extends StatefulWidget {
  const SearchTransactionsPage({super.key});

  @override
  State<SearchTransactionsPage> createState() => _SearchTransactionsPageState();
}

class _SearchTransactionsPageState extends State<SearchTransactionsPage> {
  final _keywordController = TextEditingController();
  List<ExpenseTransaction> _results = [];
  bool _isLoading = false;
  TransactionType? _selectedType;
  String? _selectedCategory;

  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _categories = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Học tập',
    'Hóa đơn',
    'Giải trí',
    'Lương',
    'Thưởng',
    'Tiền được cho',
    'Đầu tư',
    'Khác',
  ];
  @override
  void initState() {
    super.initState();
    _searchTransactions();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) return;

    if (isStartDate && _endDate != null && selectedDate.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày bắt đầu không thể sau ngày kết thúc.'),
        ),
      );
      return;
    }

    if (!isStartDate &&
        _startDate != null &&
        selectedDate.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không thể trước ngày bắt đầu.'),
        ),
      );
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDate = selectedDate;
      } else {
        _endDate = selectedDate;
      }
    });

    _searchTransactions();
  }

  Future<void> _searchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseService.instance.searchTransactions(
        keyword: _keywordController.text,
        type: _selectedType,
        category: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _results = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
    }
  }

  void _resetFilters() {
    setState(() {
      _keywordController.clear();
      _selectedType = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
    });

    _searchTransactions();
  }

  Future<void> _deleteTransaction(ExpenseTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: Text(
          'Bạn có chắc muốn xóa giao dịch "${transaction.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await DatabaseService.instance.deleteTransaction(transaction.id!);

      if (!mounted) return;

      await _searchTransactions();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa giao dịch thành công.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi xóa giao dịch: $e')));
    }
  }

  Future<void> _editTransaction(ExpenseTransaction transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(transaction: transaction),
      ),
    );

    if (result == true && mounted) {
      await _searchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm giao dịch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TransactionFilter(
            keywordController: _keywordController,
            selectedType: _selectedType,
            selectedCategory: _selectedCategory,
            categories: _categories,
            startDate: _startDate,
            endDate: _endDate,
            onKeywordChanged: (_) => _searchTransactions(),
            onClearKeyword: () {
              _keywordController.clear();
              _searchTransactions();
            },
            onTypeChanged: (type) {
              setState(() {
                _selectedType = type;
              });
              _searchTransactions();
            },
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
              _searchTransactions();
            },
            onSelectStartDate: () => _selectDate(isStartDate: true),
            onSelectEndDate: () => _selectDate(isStartDate: false),
            onReset: _resetFilters,
          ),
          const SizedBox(height: 24),

          const Text(
            'Kết quả giao dịch',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_results.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Không tìm thấy giao dịch phù hợp.'),
              ),
            )
          else ...[
            Text('Tìm thấy ${_results.length} giao dịch'),
            const SizedBox(height: 8),

            ..._results.map(
              (transaction) => TransactionListItem(
                transaction: transaction,
                onEdit: () => _editTransaction(transaction),
                onDelete: () => _deleteTransaction(transaction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

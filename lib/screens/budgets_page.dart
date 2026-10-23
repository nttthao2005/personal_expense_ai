import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../widgets/budgets/budget_form_dialog.dart';
import '../models/budget_summary.dart';
import '../services/database_service.dart';
import '../widgets/budgets/budget_overview_card.dart';
import '../services/transaction_change_notifier.dart';

class BudgetsPage extends StatefulWidget {
  final bool embedded;

  const BudgetsPage({super.key, this.embedded = false});

  @override
  State<BudgetsPage> createState() => BudgetsPageState();
}

class BudgetsPageState extends State<BudgetsPage> {
  late String _selectedMonth;
  List<BudgetSummary> _summaries = [];
  bool _isLoading = true;

  final _moneyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    _loadBudgets();
    TransactionChangeNotifier.instance.addListener(_onTransactionsChanged);
  }

  void _onTransactionsChanged() {
    debugPrint('BudgetsPage: nhận thông báo giao dịch thay đổi');

    if (!mounted) return;

    _loadBudgets();
  }

  @override
  void dispose() {
    TransactionChangeNotifier.instance.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summaries = await DatabaseService.instance
          .getBudgetSummariesByMonth(_selectedMonth);

      if (!mounted) return;

      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải danh sách ngân sách.')),
      );
    }
  }

  String _formatMoney(double amount) {
    return '${_moneyFormat.format(amount)} ₫';
  }

  double get _totalBudget =>
      _summaries.fold(0, (total, item) => total + item.budget.amount);

  double get _totalSpent =>
      _summaries.fold(0, (total, item) => total + item.spent);

  double get _totalRemaining => _totalBudget - _totalSpent;
  void _changeMonth(int offset) {
    final parts = _selectedMonth.split('-');
    final current = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    final next = DateTime(current.year, current.month + offset);

    setState(() {
      _selectedMonth = '${next.year}-${next.month.toString().padLeft(2, '0')}';
    });

    _loadBudgets();
  }

  Future<void> showBudgetForm() async {
    final budget = await showDialog<Budget>(
      context: context,
      builder: (context) => BudgetFormDialog(month: _selectedMonth),
    );

    if (budget == null || !mounted) return;

    try {
      final existingBudget = _summaries.any(
        (summary) => summary.budget.category == budget.category,
      );

      if (existingBudget) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Danh mục "${budget.category}" đã có ngân sách '
              'trong tháng $_selectedMonth.',
            ),
          ),
        );
        return;
      }

      await DatabaseService.instance.saveBudget(budget);

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ngân sách thành công.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể lưu ngân sách.')));
    }
  }

  Future<void> _editBudget(BudgetSummary summary) async {
    final updatedBudget = await showDialog<Budget>(
      context: context,
      builder: (context) =>
          BudgetFormDialog(month: _selectedMonth, budget: summary.budget),
    );

    if (updatedBudget == null || !mounted) return;

    try {
      await DatabaseService.instance.updateBudget(updatedBudget);

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ngân sách thành công.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật ngân sách.')),
      );
    }
  }

  Future<void> _deleteBudget(BudgetSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ngân sách?'),
        content: Text(
          'Bạn có chắc muốn xóa ngân sách '
          '"${summary.budget.category}" của tháng $_selectedMonth không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final id = summary.budget.id;

      if (id == null) {
        throw StateError('Ngân sách chưa có ID.');
      }

      await DatabaseService.instance.deleteBudget(id);

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ngân sách thành công.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể xóa ngân sách.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Ngân sách'),
              actions: [
                IconButton(
                  onPressed: showBudgetForm,
                  icon: const Icon(Icons.add),
                  tooltip: 'Thêm ngân sách',
                ),
              ],
            ),
      body: Column(
        children: [
          BudgetOverviewCard(
            totalBudget: _totalBudget,
            totalSpent: _totalSpent,
            totalRemaining: _totalRemaining,
            selectedMonth: DateTime(
              int.parse(_selectedMonth.split('-')[0]),
              int.parse(_selectedMonth.split('-')[1]),
            ),
            onPreviousMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summaries.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tháng này chưa có ngân sách.\n'
                        'Hãy thêm ngân sách để theo dõi chi tiêu.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _summaries.length,
                    itemBuilder: (context, index) {
                      final summary = _summaries[index];
                      final ratio = summary.usageRatio.clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: summary.isOverBudget
                                ? const Color(0xFFF2CACA)
                                : const Color(0xFFE7ECF2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF173B67)
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên danh mục và nút thao tác
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: summary.isOverBudget
                                        ? const Color(0xFFFFEEEE)
                                        : const Color(0xFFEDF3FA),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    summary.isOverBudget
                                        ? Icons.warning_amber_rounded
                                        : Icons.category_outlined,
                                    color: summary.isOverBudget
                                        ? const Color(0xFFD94F4F)
                                        : const Color(0xFF173B67),
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    summary.budget.category,
                                    style: const TextStyle(
                                      color: Color(0xFF24364B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _editBudget(summary),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  color: const Color(0xFF52677F),
                                  tooltip: 'Chỉnh sửa ngân sách',
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteBudget(summary),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: const Color(0xFFD94F4F),
                                  tooltip: 'Xóa ngân sách',
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Số tiền đã chi và hạn mức trên cùng một hàng
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ĐÃ CHI',
                                        style: TextStyle(
                                          color: Color(0xFF7B8797),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatMoney(summary.spent),
                                        style: const TextStyle(
                                          color: Color(0xFF173B67),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'HẠN MỨC',
                                        style: TextStyle(
                                          color: Color(0xFF7B8797),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatMoney(summary.budget.amount),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: Color(0xFF52677F),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tiến độ sử dụng ngân sách
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mức sử dụng',
                                  style: TextStyle(
                                    color: Color(0xFF52677F),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${(summary.usageRatio * 100).round()}%',
                                  style: TextStyle(
                                    color: summary.isOverBudget
                                        ? const Color(0xFFD94F4F)
                                        : const Color(0xFF173B67),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE8EDF3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  summary.isOverBudget
                                      ? const Color(0xFFD94F4F)
                                      : const Color(0xFF16856B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Số tiền còn lại hoặc cảnh báo vượt hạn mức
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: summary.isOverBudget
                                    ? const Color(0xFFFFF1F1)
                                    : const Color(0xFFEDF8F3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    summary.isOverBudget
                                        ? Icons.warning_amber_rounded
                                        : Icons.savings_outlined,
                                    size: 17,
                                    color: summary.isOverBudget
                                        ? const Color(0xFFD94F4F)
                                        : const Color(0xFF16856B),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      summary.isOverBudget
                                          ? 'Đã vượt ${_formatMoney(-summary.remaining)}'
                                          : 'Còn lại ${_formatMoney(summary.remaining)}',
                                      style: TextStyle(
                                        color: summary.isOverBudget
                                            ? const Color(0xFFD94F4F)
                                            : const Color(0xFF16856B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

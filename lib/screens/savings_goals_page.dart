import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/savings_goal.dart';
import '../services/database_service.dart';
import '../widgets/savings/savings_goal_form_dialog.dart';

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  SavingsGoalsPageState createState() => SavingsGoalsPageState();
}

class SavingsGoalsPageState extends State<SavingsGoalsPage> {
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await DatabaseService.instance.getSavingsGoals();

      if (!mounted) return;

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải danh sách mục tiêu tiết kiệm.'),
        ),
      );
    }
  }

  Future<void> showCreateGoalForm() async {
    final goal = await showDialog<SavingsGoal>(
      context: context,
      builder: (context) => const SavingsGoalFormDialog(),
    );

    if (goal == null || !mounted) return;

    try {
      await DatabaseService.instance.insertSavingsGoal(goal);

      if (!mounted) return;

      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo mục tiêu tiết kiệm.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Lỗi tạo mục tiêu tiết kiệm: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tạo mục tiêu tiết kiệm.')),
      );
    }
  }

  Future<void> showEditGoalForm(SavingsGoal goal) async {
    final updatedGoal = await showDialog<SavingsGoal>(
      context: context,
      builder: (context) => SavingsGoalFormDialog(initialGoal: goal),
    );

    if (updatedGoal == null || !mounted) return;

    try {
      await DatabaseService.instance.updateSavingsGoal(updatedGoal);

      if (!mounted) return;

      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật mục tiêu tiết kiệm.')),
      );
    } catch (error) {
      debugPrint('Lỗi chỉnh sửa mục tiêu tiết kiệm: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật mục tiêu tiết kiệm.')),
      );
    }
  }

  Future<void> _showDeleteGoalDialog(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa mục tiêu tiết kiệm'),
        content: Text(
          'Bạn có chắc muốn xóa mục tiêu "${goal.name}" không? '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || goal.id == null) return;

    try {
      await DatabaseService.instance.deleteSavingsGoal(goal.id!);

      if (!mounted) return;
      await _loadGoals();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa mục tiêu tiết kiệm.')),
      );
    } catch (error) {
      debugPrint('Lỗi xóa mục tiêu tiết kiệm: $error');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa mục tiêu tiết kiệm.')),
      );
    }
  }

  Future<void> _showUpdateSavedAmountDialog(SavingsGoal goal) async {
    final newAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => _UpdateSavedAmountDialog(goal: goal),
    );

    if (newAmount == null || !mounted || goal.id == null) return;

    try {
      await DatabaseService.instance.updateSavingsGoal(
        SavingsGoal(
          id: goal.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          savedAmount: newAmount,
          deadline: goal.deadline,
          createdAt: goal.createdAt,
        ),
      );

      if (!mounted) return;

      await _loadGoals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật số tiền tiết kiệm.')),
      );
    } catch (error) {
      debugPrint('Lỗi cập nhật số tiền tiết kiệm: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật số tiền tiết kiệm.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSaved = _goals.fold<double>(
      0,
      (total, goal) => total + goal.savedAmount,
    );
    final totalTarget = _goals.fold<double>(
      0,
      (total, goal) => total + goal.targetAmount,
    );
    final completedCount = _goals.where((goal) => goal.isCompleted).length;

    return RefreshIndicator(
      onRefresh: _loadGoals,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildOverviewCard(
            totalSaved: totalSaved,
            totalTarget: totalTarget,
            goalCount: _goals.length,
            completedCount: completedCount,
          ),
          const SizedBox(height: 8),
          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 36, bottom: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 48,
                    color: Colors.blueGrey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có mục tiêu tiết kiệm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF24364B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhấn nút + để tạo mục tiêu đầu tiên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF7B8797)),
                  ),
                ],
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                'Mục tiêu của bạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF24364B),
                ),
              ),
            ),
            for (final goal in _goals) _buildGoalCard(goal),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required double totalSaved,
    required double totalTarget,
    required int goalCount,
    required int completedCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF173B67),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B67).withValues(alpha: 0.12),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tổng quan tiết kiệm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TỔNG TIỀN ĐÃ TIẾT KIỆM',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _currencyFormat.format(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Mục tiêu tổng: ${_currencyFormat.format(totalTarget)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalTarget > 0
                  ? (totalSaved / totalTarget).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF72E0B3),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildOverviewInfo(
                  label: 'Tổng mục tiêu',
                  value: '$goalCount',
                  icon: Icons.flag_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewInfo(
                  label: 'Đã hoàn thành',
                  value: '$completedCount',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF72E0B3), size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final progress = goal.progress.clamp(0.0, 1.0);
    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
      0.0,
      double.infinity,
    );
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFCDE9DC)
              : const Color(0xFFE7ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B67).withValues(alpha: 0.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFEDF8F3)
                      : const Color(0xFFEDF3FA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline
                      : Icons.flag_outlined,
                  color: isCompleted
                      ? const Color(0xFF16856B)
                      : const Color(0xFF173B67),
                  size: 21,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    color: Color(0xFF24364B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16856B),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ĐÃ TIẾT KIỆM',
                      style: TextStyle(
                        color: Color(0xFF7B8797),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(goal.savedAmount),
                      style: const TextStyle(
                        color: Color(0xFF173B67),
                        fontSize: 17,
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
                      'MỤC TIÊU',
                      style: TextStyle(
                        color: Color(0xFF7B8797),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(goal.targetAmount),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ',
                style: TextStyle(color: Color(0xFF52677F), fontSize: 11),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: isCompleted
                      ? const Color(0xFF16856B)
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
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8EDF3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF16856B) : const Color(0xFF173B67),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF8F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: Color(0xFF16856B),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Còn cần ${_currencyFormat.format(remaining)}',
                      style: const TextStyle(
                        color: Color(0xFF16856B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Đã hoàn thành mục tiêu',
                style: TextStyle(
                  color: Color(0xFF16856B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: Color(0xFF7B8797),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Hạn: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
                    style: const TextStyle(
                      color: Color(0xFF7B8797),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: () => showEditGoalForm(goal),
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: const Color(0xFF52677F),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                tooltip: 'Cập nhật số tiền',
                onPressed: () => _showUpdateSavedAmountDialog(goal),
                icon: const Icon(Icons.savings_outlined, size: 20),
                color: const Color(0xFF16856B),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                tooltip: 'Xóa mục tiêu',
                onPressed: () => _showDeleteGoalDialog(goal),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFD94F4F),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateSavedAmountDialog extends StatefulWidget {
  final SavingsGoal goal;

  const _UpdateSavedAmountDialog({required this.goal});

  @override
  State<_UpdateSavedAmountDialog> createState() =>
      _UpdateSavedAmountDialogState();
}

class _UpdateSavedAmountDialogState extends State<_UpdateSavedAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.goal.savedAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(double.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;

    return AlertDialog(
      title: Text('Cập nhật: ${goal.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Số tiền đã tiết kiệm (VNĐ)',
            hintText: 'Ví dụ: 5000000',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final amount = double.tryParse(value?.trim() ?? '');

            if (amount == null || !amount.isFinite || amount < 0) {
              return 'Nhập số tiền từ 0 trở lên';
            }

            if (amount > goal.targetAmount) {
              return 'Số tiền không được vượt quá mục tiêu';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}

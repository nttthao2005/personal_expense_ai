import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final DateTime selectedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  const BudgetOverviewCard({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.selectedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  static const Color _navy = Color(0xFF173B67);
  static const Color _green = Color(0xFF16856B);
  static const Color _red = Color(0xFFD94F4F);
  static const Color _lightTrack = Color(0xFFE4EAF1);

  String _formatMoney(double amount) {
    return '${NumberFormat('#,##0', 'vi_VN').format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final isOverBudget = totalRemaining < 0;
    final ratio = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    final progressColor = isOverBudget ? _red : _green;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tổng quan ngân sách',
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
          // Bộ chọn tháng
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                tooltip: 'Tháng trước',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('MM/yyyy').format(selectedMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                tooltip: 'Tháng sau',
                visualDensity: VisualDensity.compact,

                color: Colors.white,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tổng ngân sách
          Text(
            'TỔNG NGÂN SÁCH',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMoney(totalBudget),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          // Đã chi và số tiền còn lại
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAmountInfo(
                  label: 'Đã chi',
                  amount: _formatMoney(totalSpent),
                  icon: Icons.trending_up,
                  amountColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAmountInfo(
                  label: isOverBudget ? 'Vượt ngân sách' : 'Còn lại',
                  amount: _formatMoney(totalRemaining.abs()),
                  icon: isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.savings_outlined,
                  amountColor: isOverBudget
                      ? const Color(0xFFFFA5A5)
                      : const Color(0xFF72E0B3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Thanh tiến độ
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: _lightTrack.withValues(alpha: 0.28),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã sử dụng ${(ratio * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11,
                ),
              ),
              if (isOverBudget)
                const Text(
                  'Cần điều chỉnh',
                  style: TextStyle(
                    color: Color(0xFFFFA5A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo({
    required String label,
    required String amount,
    required IconData icon,
    required Color amountColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: amountColor, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsOverviewSection extends StatelessWidget {
  final String selectedPeriod;
  final String periodLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final ValueChanged<String> onPeriodChanged;
  const StatisticsOverviewSection({
    super.key,
    required this.selectedPeriod,
    required this.periodLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.onPeriodChanged,
    this.onPrevious,
    this.onNext,
  });

  static const Color _navy = Color(0xFF173B67);
  static const Color _green = Color(0xFF16856B);
  static const Color _lightText = Color(0xFFDCE8F8);

  String _formatMoney(double amount) {
    return '${NumberFormat('#,##0', 'vi_VN').format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề báo cáo tài chính.
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BÁO CÁO TÀI CHÍNH',
                      style: TextStyle(
                        color: _lightText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thống kê thu chi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 14),

          // Điều hướng kỳ thống kê.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng quan tài chính',
                  style: TextStyle(color: _lightText, fontSize: 13),
                ),
              ),
              if (selectedPeriod != 'Tùy chỉnh')
                IconButton(
                  onPressed: onPrevious,
                  tooltip: 'Kỳ trước',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: Colors.white,
                ),
              Flexible(
                child: Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selectedPeriod != 'Tùy chỉnh')
                IconButton(
                  onPressed: onNext,
                  tooltip: 'Kỳ tiếp theo',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Hai chỉ số thu nhập và chi tiêu nằm trong khối navy.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAmountCard(
                  title: 'Tổng thu nhập',
                  amount: totalIncome,
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF8DE0B7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAmountCard(
                  title: 'Tổng chi tiêu',
                  amount: totalExpense,
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFFFFB5B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Số dư nổi bật bên trong khối xanh.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư thu chi',
                  style: TextStyle(color: Color(0xFF52647A), fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatMoney(balance),
                  style: TextStyle(
                    color: balance >= 0 ? _green : const Color(0xFFD9534F),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Thu nhập trừ chi tiêu trong kỳ',
                  style: TextStyle(color: Color(0xFF65758B), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bộ lọc thời gian cũng nằm trong khối navy.
          Row(
            children: [
              _buildPeriodButton('Ngày'),
              const SizedBox(width: 5),
              _buildPeriodButton('Tháng'),
              const SizedBox(width: 5),
              _buildPeriodButton('Năm'),
              const SizedBox(width: 5),
              _buildPeriodButton('Tùy chỉnh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: _lightText, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            _formatMoney(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: Material(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => onPeriodChanged(period),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
            child: Text(
              period,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? _navy : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

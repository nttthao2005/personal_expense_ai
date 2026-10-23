import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseCategoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> categoryTotals;
  final String selectedView;
  final ValueChanged<String> onViewChanged;

  const ExpenseCategoryChart({
    super.key,
    required this.categoryTotals,
    required this.selectedView,
    required this.onViewChanged,
  });
  static const List<Color> _colors = [
    Color(0xFF16856B),
    Color(0xFF4285F4),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
    Color(0xFF78909C),
    Color(0xFF8D6E63),
  ];

  String _formatMoney(double amount) {
    return '${NumberFormat('#,##0', 'vi_VN').format(amount)} ₫';
  }

  Widget _buildViewButton(String view) {
    final isSelected = selectedView == view;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onViewChanged(view),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF173B67) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            view,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF526477),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as num).toDouble(),
    );

    final hasData = categoryTotals.isNotEmpty && total > 0;

    final totalLabel = selectedView == 'Thu nhập' ? 'Tổng thu:' : 'Tổng chi:';

    final emptyMessage = selectedView == 'Thu nhập'
        ? 'Chưa có dữ liệu thu nhập theo danh mục trong kỳ này.'
        : 'Chưa có dữ liệu chi tiêu theo danh mục trong kỳ này.';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân loại thu chi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 239, 241, 247),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildViewButton('Chi tiêu'),
                  _buildViewButton('Thu nhập'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!hasData)
              SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 48,
                    sectionsSpace: 3,
                    sections: List.generate(categoryTotals.length, (index) {
                      final item = categoryTotals[index];
                      final amount = (item['total'] as num).toDouble();
                      final percent = amount / total * 100;

                      return PieChartSectionData(
                        color: _colors[index % _colors.length],
                        value: amount,
                        title: '${percent.toStringAsFixed(1)}%',
                        radius: 62,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$totalLabel ${_formatMoney(total)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...List.generate(categoryTotals.length, (index) {
                final item = categoryTotals[index];
                final category = item['category'] as String;
                final amount = (item['total'] as num).toDouble();
                final percent = amount / total * 100;
                final color = _colors[index % _colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(category)),
                      const SizedBox(width: 8),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formatMoney(amount),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

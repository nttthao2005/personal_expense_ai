import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/trend_data.dart';

class CashFlowTrendChart extends StatelessWidget {
  final List<TrendData> trendData;
  final String selectedPeriod;

  const CashFlowTrendChart({
    super.key,
    required this.trendData,
    required this.selectedPeriod,
  });

  static const Color _incomeColor = Color(0xFF16856B);
  static const Color _expenseColor = Color(0xFF4285F4);

  String _formatMoney(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    }

    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)} tr';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k';
    }

    return amount.toStringAsFixed(0);
  }

  String _formatPeriod(String period) {
    if (selectedPeriod == 'Năm') {
      // Dữ liệu dạng yyyy, ví dụ 2024.
      return period;
    }

    if (selectedPeriod == 'Tháng') {
      // Dữ liệu dạng yyyy-MM, ví dụ 2026-03.
      final date = DateTime.tryParse('$period-01');

      if (date == null) return period;

      return 'T${date.month}';
    }

    return period;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trendData.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(top: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xu hướng dòng tiền',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Chưa có dữ liệu dòng tiền trong kỳ này.'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxValue = trendData.fold<double>(0, (current, item) {
      final periodMax = item.income > item.expense ? item.income : item.expense;
      return periodMax > current ? periodMax : current;
    });

    final interval = maxValue <= 0 ? 1.0 : maxValue / 4;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF173B67),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xu hướng thu chi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF173B67),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedPeriod == 'Năm'
                            ? 'So sánh thu nhập và chi tiêu theo năm'
                            : 'So sánh thu nhập và chi tiêu theo tháng',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegend(_incomeColor, 'Thu nhập'),
                const SizedBox(width: 20),
                _buildLegend(_expenseColor, 'Chi tiêu'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue <= 0 ? 1 : maxValue * 1.15,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Thu nhập' : 'Chi tiêu';

                        return BarTooltipItem(
                          '$label\n${NumberFormat('#,##0', 'vi_VN').format(rod.toY)} ₫',
                          TextStyle(
                            color: rod.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatMoney(value),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= trendData.length) {
                            return const SizedBox.shrink();
                          }

                          // Tránh nhãn ngày bị chồng lên nhau.
                          if (selectedPeriod == 'Tháng' &&
                              trendData.length > 10 &&
                              index % 5 != 0 &&
                              index != trendData.length - 1) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _formatPeriod(trendData[index].period),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(trendData.length, (index) {
                    final item = trendData[index];

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          color: _incomeColor,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: item.expense,
                          color: _expenseColor,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

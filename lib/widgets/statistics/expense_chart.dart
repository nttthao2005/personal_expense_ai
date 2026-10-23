import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpenseChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyTotals;

  const ExpenseChart({super.key, required this.dailyTotals});

  @override
  Widget build(BuildContext context) {
    if (dailyTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chưa có dữ liệu trong khoảng thời gian này',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Hãy thử chọn kỳ khác hoặc thêm giao dịch mới.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxAmount = dailyTotals.fold<double>(0, (max, item) {
      final income = (item['income'] as num).toDouble();
      final expense = (item['expense'] as num).toDouble();
      final dailyMax = income > expense ? income : expense;

      return dailyMax > max ? dailyMax : max;
    });

    final interval = maxAmount <= 0 ? 1.0 : maxAmount / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thu chi theo ngày',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxAmount <= 0 ? 4 : maxAmount * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
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
                          return Text(
                            value >= 1000000
                                ? '${(value / 1000000).toStringAsFixed(1)}tr'
                                : value >= 1000
                                ? '${(value / 1000).toStringAsFixed(0)}k'
                                : value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= dailyTotals.length) {
                            return const SizedBox.shrink();
                          }

                          final day = dailyTotals[index]['day'] as String;
                          final parts = day.split('-');

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              parts.length == 3
                                  ? '${parts[2]}/${parts[1]}'
                                  : day,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(dailyTotals.length, (index) {
                    final item = dailyTotals[index];
                    final income = (item['income'] as num).toDouble();
                    final expense = (item['expense'] as num).toDouble();

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: const Color(0xFF16856B),
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: Colors.redAccent,
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _ChartLegend(color: Color(0xFF16856B), label: 'Thu'),
                _ChartLegend(color: Colors.redAccent, label: 'Chi'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

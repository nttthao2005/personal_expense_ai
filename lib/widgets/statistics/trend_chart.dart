import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/trend_data.dart';

class TrendChart extends StatelessWidget {
  final List<TrendData> trendData;
  final String period;

  const TrendChart({super.key, required this.trendData, required this.period});

  String _formatPeriod(String value) {
    if (period == 'Năm') {
      return value;
    }

    if (period == 'Tháng') {
      final parts = value.split('-');
      return parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : value;
    }

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Chưa có dữ liệu xu hướng thu chi.')),
        ),
      );
    }

    final maxAmount = trendData.fold<double>(0, (max, item) {
      final itemMax = item.income > item.expense ? item.income : item.expense;
      return itemMax > max ? itemMax : max;
    });

    final interval = maxAmount <= 0 ? 1.0 : maxAmount / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biến động thu chi theo ${period.toLowerCase()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          final label = value >= 1000000
                              ? '${(value / 1000000).toStringAsFixed(1)}tr'
                              : value >= 1000
                              ? '${(value / 1000).toStringAsFixed(0)}k'
                              : value.toStringAsFixed(0);

                          return Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= trendData.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatPeriod(trendData[index].period),
                              style: const TextStyle(fontSize: 10),
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
                          color: const Color(0xFF16856B),
                          width: 8,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: item.expense,
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
                _TrendLegend(color: Color(0xFF16856B), label: 'Thu'),
                _TrendLegend(color: Colors.redAccent, label: 'Chi'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _TrendLegend({required this.color, required this.label});

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

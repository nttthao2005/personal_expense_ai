import 'package:flutter/material.dart';

import '../../models/trend_data.dart';
import 'cash_flow_trend_chart.dart';
import 'expense_category_chart.dart';

class StatisticsChartSection extends StatelessWidget {
  final String selectedView;
  final String selectedPeriod;
  final ValueChanged<String> onViewChanged;
  final List<TrendData> trendData;
  final List<Map<String, dynamic>> expenseCategoryTotals;
  final List<Map<String, dynamic>> incomeCategoryTotals;

  const StatisticsChartSection({
    super.key,
    required this.selectedView,
    required this.selectedPeriod,
    required this.trendData,
    required this.expenseCategoryTotals,
    required this.incomeCategoryTotals,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categoryTotals = selectedView == 'Thu nhập'
        ? incomeCategoryTotals
        : expenseCategoryTotals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseCategoryChart(
          categoryTotals: categoryTotals,
          selectedView: selectedView,
          onViewChanged: onViewChanged,
        ),

        if (selectedPeriod == 'Tháng' || selectedPeriod == 'Năm')
          CashFlowTrendChart(
            trendData: trendData,
            selectedPeriod: selectedPeriod,
          ),
      ],
    );
  }
}

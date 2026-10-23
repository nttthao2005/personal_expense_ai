class StatisticsData {
  final Map<String, double> totals;
  final List<Map<String, dynamic>> dailyTotals;
  final List<Map<String, dynamic>> expenseCategoryTotals;
  final List<Map<String, dynamic>> incomeCategoryTotals;

  const StatisticsData({
    required this.totals,
    required this.dailyTotals,
    required this.expenseCategoryTotals,
    required this.incomeCategoryTotals,
  });
}

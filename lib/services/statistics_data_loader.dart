import '../models/statistics_data.dart';
import '../models/transaction.dart';
import 'database_service.dart';
import '../models/trend_data.dart';

class StatisticsDataLoader {
  StatisticsDataLoader._();

  static final StatisticsDataLoader instance = StatisticsDataLoader._();

  Future<StatisticsData> load({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final database = DatabaseService.instance;

    final results = await Future.wait([
      database.getTotalsForDateRange(startDate: startDate, endDate: endDate),
      database.getDailyTotalsForDateRange(
        startDate: startDate,
        endDate: endDate,
      ),
      database.getTotalsByCategory(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.expense,
      ),
      database.getTotalsByCategory(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.income,
      ),
    ]);

    return StatisticsData(
      totals: results[0] as Map<String, double>,
      dailyTotals: results[1] as List<Map<String, dynamic>>,
      expenseCategoryTotals: results[2] as List<Map<String, dynamic>>,
      incomeCategoryTotals: results[3] as List<Map<String, dynamic>>,
    );
  }

  Future<List<TrendData>> loadTrend({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) {
    return DatabaseService.instance.getTrendTotals(
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
  }
}

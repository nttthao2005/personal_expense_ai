import 'package:flutter/material.dart';

import '../models/trend_data.dart';
import '../services/statistics_data_loader.dart';
import '../widgets/statistics/trend_chart.dart';

class TrendPage extends StatefulWidget {
  const TrendPage({super.key});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  String _selectedPeriod = 'Tuần';
  List<TrendData> _trendTotals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrendStatistics();
  }

  Future<void> _loadTrendStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final today = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (_selectedPeriod) {
      case 'Tuần':
        endDate = DateTime(today.year, today.month, today.day);
        startDate = endDate.subtract(const Duration(days: 35));
        startDate = startDate.subtract(Duration(days: startDate.weekday - 1));
        break;

      case 'Tháng':
        endDate = DateTime(today.year, today.month + 1, 0);
        startDate = DateTime(today.year, today.month - 5, 1);
        break;

      case 'Năm':
        endDate = DateTime(today.year, 12, 31);
        startDate = DateTime(today.year - 5, 1, 1);
        break;
    }

    try {
      final data = await StatisticsDataLoader.instance.loadTrend(
        startDate: startDate,
        endDate: endDate,
        period: _selectedPeriod,
      );

      final filledData = <TrendData>[];

      if (_selectedPeriod == 'Tuần') {
        var current = startDate;
        for (var i = 0; i < 6; i++) {
          final key =
              '${current.year.toString().padLeft(4, '0')}-'
              '${current.month.toString().padLeft(2, '0')}-'
              '${current.day.toString().padLeft(2, '0')}';

          final matches = data.where((item) => item.period == key);

          filledData.add(
            matches.isNotEmpty
                ? matches.first
                : TrendData(period: key, income: 0, expense: 0),
          );

          current = current.add(const Duration(days: 7));
        }
      } else if (_selectedPeriod == 'Tháng') {
        var current = DateTime(startDate.year, startDate.month, 1);

        while (!current.isAfter(endDate)) {
          final key =
              '${current.year.toString().padLeft(4, '0')}-'
              '${current.month.toString().padLeft(2, '0')}';

          final matches = data.where((item) => item.period == key);

          filledData.add(
            matches.isNotEmpty
                ? matches.first
                : TrendData(period: key, income: 0, expense: 0),
          );

          current = DateTime(current.year, current.month + 1, 1);
        }
      } else {
        for (var year = startDate.year; year <= endDate.year; year++) {
          final key = year.toString();
          final matches = data.where((item) => item.period == key);

          filledData.add(
            matches.isNotEmpty
                ? matches.first
                : TrendData(period: key, income: 0, expense: 0),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _trendTotals = filledData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu xu hướng thu chi: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu xu hướng thu chi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xu hướng thu chi'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xem biến động theo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Tuần', label: Text('Tuần')),
                ButtonSegment(value: 'Tháng', label: Text('Tháng')),
                ButtonSegment(value: 'Năm', label: Text('Năm')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedPeriod = selection.first;
                });
                _loadTrendStatistics();
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Column(
                  children: [
                    Text(_errorMessage!),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadTrendStatistics,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else
              TrendChart(trendData: _trendTotals, period: _selectedPeriod),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/statistics/date_range_filter.dart';
import '../widgets/statistics/statistics_overview_section.dart';
import '../widgets/statistics/statistics_chart_section.dart';
import '../services/statistics_data_loader.dart';
import '../services/ai_analysis_service.dart';
import '../models/trend_data.dart';
import '../services/transaction_change_notifier.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod = 'Tháng';
  String _selectedView = 'Chi tiêu';
  List<TrendData> _trendData = [];
  DateTime _selectedDate = DateTime.now();
  bool _isAIResultExpanded = true;
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'Ngày':
        return 'Ngày ${_selectedDate.day.toString().padLeft(2, '0')}/'
            '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year}';

      case 'Năm':
        return 'Năm ${_selectedDate.year}';

      case 'Tùy chỉnh':
        if (_startDate == null || _endDate == null) {
          return 'Vui lòng chọn ngày bắt đầu và kết thúc';
        }

        return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';

      default:
        return 'Tháng ${_selectedDate.month}, ${_selectedDate.year}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, double> _totals = {'income': 0, 'expense': 0, 'balance': 0};

  List<Map<String, dynamic>> _categoryTotals = [];
  List<Map<String, dynamic>> _incomeCategoryTotals = [];
  bool _isLoading = true;
  final AiAnalysisService _aiAnalysisService = AiAnalysisService();

  bool _isAnalyzingAI = false;
  String? _aiAnalysisResult;
  @override
  void initState() {
    super.initState();

    TransactionChangeNotifier.instance.addListener(_onTransactionsChanged);

    _loadStatistics();
  }

  void _onTransactionsChanged() {
    if (!mounted) return;

    if (_selectedPeriod == 'Tùy chỉnh' &&
        _startDate != null &&
        _endDate != null) {
      _loadCustomStatistics();
    } else {
      _loadStatistics();
    }
  }

  @override
  void dispose() {
    TransactionChangeNotifier.instance.removeListener(_onTransactionsChanged);

    super.dispose();
  }

  void _changePeriod(int direction) {
    setState(() {
      _aiAnalysisResult = null;
      switch (_selectedPeriod) {
        case 'Ngày':
          _selectedDate = _selectedDate.add(Duration(days: direction));
          break;

        case 'Năm':
          _selectedDate = DateTime(
            _selectedDate.year + direction,
            _selectedDate.month,
            1,
          );
          break;

        case 'Tháng':
        default:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + direction,
            1,
          );
          break;
      }
    });

    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    DateTime startDate;
    DateTime endDate;

    if (_selectedPeriod == 'Ngày') {
      startDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      endDate = startDate;
    } else if (_selectedPeriod == 'Năm') {
      startDate = DateTime(_selectedDate.year, 1, 1);
      endDate = DateTime(_selectedDate.year, 12, 31);
    } else {
      startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    }

    try {
      final data = await StatisticsDataLoader.instance.load(
        startDate: startDate,
        endDate: endDate,
      );

      final List<TrendData> trendData;

      if (_selectedPeriod == 'Tháng') {
        // Lấy 6 tháng gần nhất, tính cả tháng đang chọn.
        final trendStartDate = DateTime(
          _selectedDate.year,
          _selectedDate.month - 5,
          1,
        );

        final trendEndDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          0,
        );

        trendData = await StatisticsDataLoader.instance.loadTrend(
          startDate: trendStartDate,
          endDate: trendEndDate,
          period: _selectedPeriod,
        );
      } else if (_selectedPeriod == 'Năm') {
        // Lấy 6 năm gần nhất, tính cả năm đang chọn.
        final trendStartDate = DateTime(_selectedDate.year - 5, 1, 1);
        final trendEndDate = DateTime(_selectedDate.year, 12, 31);

        trendData = await StatisticsDataLoader.instance.loadTrend(
          startDate: trendStartDate,
          endDate: trendEndDate,
          period: _selectedPeriod,
        );
      } else {
        trendData = [];
      }

      if (!mounted) return;

      setState(() {
        _totals = data.totals;

        _categoryTotals = data.expenseCategoryTotals;
        _incomeCategoryTotals = data.incomeCategoryTotals;
        _trendData = trendData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu thống kê.')),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    if (_endDate != null && picked.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày bắt đầu không được sau ngày kết thúc.'),
        ),
      );
      return;
    }

    setState(() {
      _startDate = picked;
      _selectedPeriod = 'Tùy chỉnh';
    });

    await _loadCustomStatistics();
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    if (_startDate != null && picked.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không được trước ngày bắt đầu.'),
        ),
      );
      return;
    }

    setState(() {
      _endDate = picked;
      _selectedPeriod = 'Tùy chỉnh';
    });

    await _loadCustomStatistics();
  }

  Future<void> _loadCustomStatistics() async {
    if (_startDate == null || _endDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await StatisticsDataLoader.instance.load(
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;

      setState(() {
        _totals = data.totals;

        _categoryTotals = data.expenseCategoryTotals;
        _incomeCategoryTotals = data.incomeCategoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu thống kê.')),
      );
    }
  }

  Future<void> _analyzeExpensesWithAI() async {
    if (_isLoading || _isAnalyzingAI) return;

    if (_selectedPeriod == 'Tùy chỉnh' &&
        (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu và kết thúc.'),
        ),
      );
      return;
    }
    debugPrint('[AI] Bắt đầu phân tích chi tiêu');
    setState(() {
      _isAnalyzingAI = true;
      _aiAnalysisResult = null;
    });

    try {
      final categories = _categoryTotals
          .where((item) => (item['total'] as num?) != null)
          .map((item) {
            return <String, dynamic>{
              'category': item['category']?.toString() ?? 'Khác',
              'amount': (item['total'] as num).toDouble(),
            };
          })
          .where((item) => (item['amount'] as double) > 0)
          .toList();
      debugPrint('[AI] Đang gửi yêu cầu tới FastAPI');

      final result = await _aiAnalysisService.analyzeExpenses(
        period: _getPeriodLabel(),
        totalIncome: _totals['income'] ?? 0,
        totalExpense: _totals['expense'] ?? 0,
        balance: _totals['balance'] ?? 0,
        categories: categories,
      );
      debugPrint('[AI] Nhận phản hồi thành công');
      if (!mounted) return;

      setState(() {
        _aiAnalysisResult = result;
      });
    } catch (e) {
      debugPrint('[AI] Lỗi phân tích: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể phân tích bằng AI: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingAI = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatisticsOverviewSection(
                selectedPeriod: _selectedPeriod,
                periodLabel: _getPeriodLabel(),
                totalIncome: _totals['income'] ?? 0,
                totalExpense: _totals['expense'] ?? 0,
                balance: _totals['balance'] ?? 0,
                onPrevious: () => _changePeriod(-1),
                onNext: () => _changePeriod(1),
                onPeriodChanged: (period) {
                  setState(() {
                    _selectedPeriod = period;
                    _aiAnalysisResult = null;
                    if (period != 'Tùy chỉnh') {
                      _startDate = null;
                      _endDate = null;
                    }
                  });

                  if (period != 'Tùy chỉnh') {
                    _loadStatistics();
                  }
                },
              ),

              const SizedBox(height: 8),
              if (_selectedPeriod == 'Tùy chỉnh') ...[
                DateRangeFilter(
                  startDate: _startDate,
                  endDate: _endDate,
                  onSelectStartDate: _selectStartDate,
                  onSelectEndDate: _selectEndDate,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF173B67),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFDCE4EE)),
                  ),
                  onPressed: (_isLoading || _isAnalyzingAI)
                      ? null
                      : _analyzeExpensesWithAI,
                  icon: _isAnalyzingAI
                      ? const SizedBox(
                          width: 18,
                          height: 18,

                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isAnalyzingAI
                        ? 'Đang phân tích...'
                        : 'Phân tích chi tiêu bằng AI',
                  ),
                ),
              ),

              if (_aiAnalysisResult != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF173B67),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phân tích tài chính AI',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF173B67),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Nhận xét và gợi ý từ dữ liệu thu chi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: _isAIResultExpanded
                                  ? 'Thu gọn kết quả'
                                  : 'Mở rộng kết quả',
                              onPressed: () {
                                setState(() {
                                  _isAIResultExpanded = !_isAIResultExpanded;
                                });
                              },
                              icon: AnimatedRotation(
                                turns: _isAIResultExpanded ? 0 : 0.5,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Color(0xFF173B67),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isAIResultExpanded) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          SelectableText(
                            _aiAnalysisResult!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.7,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                const SizedBox(height: 8),

                StatisticsChartSection(
                  selectedView: _selectedView,
                  selectedPeriod: _selectedPeriod,
                  trendData: _trendData,
                  expenseCategoryTotals: _categoryTotals,
                  incomeCategoryTotals: _incomeCategoryTotals,
                  onViewChanged: (view) {
                    setState(() {
                      _selectedView = view;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

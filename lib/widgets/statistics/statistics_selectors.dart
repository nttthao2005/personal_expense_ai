import 'package:flutter/material.dart';

class StatisticsViewSelector extends StatelessWidget {
  final String selectedView;
  final ValueChanged<String> onViewChanged;

  const StatisticsViewSelector({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'Chi tiêu',
          label: Text('Chi tiêu'),
          icon: Icon(Icons.pie_chart_outline),
        ),
        ButtonSegment<String>(
          value: 'Thu nhập',
          label: Text('Thu nhập'),
          icon: Icon(Icons.savings_outlined),
        ),
      ],
      selected: {selectedView},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onViewChanged(selection.first);
        }
      },
      showSelectedIcon: false,
    );
  }
}

class StatisticsPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const StatisticsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  static const Color _navy = Color(0xFF173B67);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment<String>(value: 'Ngày', label: Text('Ngày')),
          ButtonSegment<String>(value: 'Tháng', label: Text('Tháng')),
          ButtonSegment<String>(value: 'Năm', label: Text('Năm')),
          ButtonSegment<String>(value: 'Tùy chỉnh', label: Text('Tùy chỉnh')),
        ],
        selected: {selectedPeriod},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onPeriodChanged(selection.first);
          }
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF52647A);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _navy;
            }
            return Colors.transparent;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Colors.transparent),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;

  const DateRangeFilter({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
  });

  String _formatDate(DateTime? date, String placeholder) {
    if (date == null) return placeholder;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Khoảng thời gian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSelectStartDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_formatDate(startDate, 'Từ ngày')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSelectEndDate,
                icon: const Icon(Icons.event),
                label: Text(_formatDate(endDate, 'Đến ngày')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

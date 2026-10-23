import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';

class TransactionListItem extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amount = NumberFormat('#,##0', 'vi_VN').format(transaction.amount);

    final color = isIncome ? const Color(0xFF16856B) : Colors.redAccent;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? const Color(0xFFE2F5EC)
            : const Color(0xFFFFE9E6),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${transaction.category} • '
        '${transaction.date.day.toString().padLeft(2, '0')}/'
        '${transaction.date.month.toString().padLeft(2, '0')}/'
        '${transaction.date.year}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : '-'}$amount ₫',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          IconButton(
            tooltip: 'Sửa giao dịch',
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: onEdit == null ? null : () => onEdit!(),
          ),
          IconButton(
            tooltip: 'Xóa giao dịch',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete == null ? null : () => onDelete!(),
          ),
        ],
      ),
    );
  }
}

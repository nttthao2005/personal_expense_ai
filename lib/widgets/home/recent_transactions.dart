import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../transactions/transaction_list_item.dart';
import '../../services/transaction_change_notifier.dart';
import '../../screens/search_transactions_page.dart';

class RecentTransactions extends StatefulWidget {
  final VoidCallback? onChanged;
  final ValueChanged<ExpenseTransaction>? onEdit;

  const RecentTransactions({super.key, this.onChanged, this.onEdit});

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  late Future<List<ExpenseTransaction>> _transactionsFuture;
  late final TransactionChangeNotifier _changeNotifier;
  @override
  void initState() {
    super.initState();

    _loadTransactions();

    _changeNotifier = TransactionChangeNotifier.instance;
    _changeNotifier.addListener(_onTransactionsChanged);
  }

  void _onTransactionsChanged() {
    if (!mounted) return;

    _refreshTransactions();
  }

  @override
  void dispose() {
    _changeNotifier.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  void _loadTransactions() {
    _transactionsFuture = DatabaseService.instance.getTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _loadTransactions();
    });
  }

  Future<void> _confirmDelete(ExpenseTransaction transaction) async {
    if (transaction.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: Text('Bạn có chắc muốn xóa "${transaction.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final deleted = await DatabaseService.instance.deleteTransaction(
        transaction.id!,
      );

      if (!mounted) return;

      if (deleted > 0) {
        _refreshTransactions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa giao dịch thành công!')),
        );

        widget.onChanged?.call();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa giao dịch. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF173B67),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchTransactionsPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 14),

        FutureBuilder<List<ExpenseTransaction>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Không thể tải giao dịch. '
                  'Hãy kiểm tra nền tảng đang chạy.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final transactions = snapshot.data ?? [];

            if (transactions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Color(0xFF16856B),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có giao dịch nào',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Các khoản thu và chi của bạn '
                      'sẽ xuất hiện ở đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            final recent = transactions.take(10).toList();

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EDF3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF173B67).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: recent
                    .map(
                      (transaction) => TransactionListItem(
                        transaction: transaction,
                        onEdit: widget.onEdit == null
                            ? null
                            : () => widget.onEdit!(transaction),
                        onDelete: () => _confirmDelete(transaction),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

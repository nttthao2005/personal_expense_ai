import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';
import 'summary_item.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  static const Color _navy = Color(0xFF173B67);

  String _formatMoney(double amount) {
    return NumberFormat('#,##0', 'vi_VN').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<double>>(
      future: Future.wait([
        DatabaseService.instance.getBalance(),
        DatabaseService.instance.getTotalIncome(),
        DatabaseService.instance.getTotalExpense(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Không thể tải số liệu thu chi.')),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: () {
                      // FutureBuilder sẽ được làm mới khi widget được tạo lại.
                      // Không thay đổi dữ liệu hoặc nghiệp vụ SQLite.
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final balance = snapshot.data![0];
        final income = snapshot.data![1];
        final expense = snapshot.data![2];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF173B67), Color(0xFF24558A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SỐ DƯ HIỆN TẠI',
                      style: TextStyle(
                        color: Color(0xFFD6E4F5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${balance < 0 ? '-' : ''}'
                '${_formatMoney(balance.abs())} ₫',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SummaryItem(
                      icon: Icons.south_west_rounded,
                      title: 'Thu nhập',
                      amount: '+${_formatMoney(income)} ₫',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryItem(
                      icon: Icons.north_east_rounded,
                      title: 'Chi tiêu',
                      amount: '-${_formatMoney(expense)} ₫',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

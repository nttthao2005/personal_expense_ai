import 'package:flutter/material.dart';

import 'add_transaction_page.dart';
import '../widgets/home/balance_card.dart';
import '../widgets/home/recent_transactions.dart';
import '../models/transaction.dart';
import 'search_transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _refreshKey = 0;

  Future<void> _openSearchTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchTransactionsPage()),
    );

    if (!mounted) return;

    setState(() {
      _refreshKey++;
    });
  }

  Future<void> _openEditTransaction(ExpenseTransaction transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(transaction: transaction),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào 👋',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              'Quản lý chi tiêu',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm giao dịch',
            onPressed: _openSearchTransactions,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(key: ValueKey('balance-$_refreshKey')),
            const SizedBox(height: 20),

            const SizedBox(height: 26),
            RecentTransactions(
              key: ValueKey('recent-$_refreshKey'),
              onChanged: () {
                if (!mounted) return;

                setState(() {
                  _refreshKey++;
                });
              },
              onEdit: _openEditTransaction,
            ),
          ],
        ),
      ),
    );
  }
}

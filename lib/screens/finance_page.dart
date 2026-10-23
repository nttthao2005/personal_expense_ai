import 'package:flutter/material.dart';

import 'savings_goals_page.dart';
import 'budgets_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final GlobalKey<BudgetsPageState> _budgetsKey = GlobalKey<BudgetsPageState>();
  final GlobalKey<SavingsGoalsPageState> _savingsKey =
      GlobalKey<SavingsGoalsPageState>();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tài chính'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: TabBar(
                  onTap: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF173B67),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  dividerColor: Colors.transparent,
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF52677F),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 18),
                          SizedBox(width: 7),
                          Text('Ngân sách'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, size: 18),
                          SizedBox(width: 7),
                          Text('Tiết kiệm'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        body: TabBarView(
          children: [
            BudgetsPage(key: _budgetsKey, embedded: true),
            SavingsGoalsPage(key: _savingsKey),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_selectedTab == 0) {
              _budgetsKey.currentState?.showBudgetForm();
            } else {
              _savingsKey.currentState?.showCreateGoalForm();
            }
          },
          tooltip: _selectedTab == 0
              ? 'Thêm ngân sách'
              : 'Thêm mục tiêu tiết kiệm',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

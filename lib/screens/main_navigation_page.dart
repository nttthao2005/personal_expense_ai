import 'package:flutter/material.dart';

import 'home_page.dart';
import 'statistics_page.dart';
import 'receipt_scan_page.dart';
import 'finance_page.dart';
import 'add_transaction_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const _ReportsPage(),
    const FinancePage(),
  ];

  void _openAddTransaction() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Nhập giao dịch thủ công'),
                  subtitle: const Text('Nhập khoản thu hoặc chi'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionPage(),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: const Text('Quét hóa đơn / ảnh chuyển khoản'),
                  subtitle: const Text('Tự động nhận diện thông tin bằng OCR'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const ReceiptScanPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _selectedIndex == 2
          ? null
          : FloatingActionButton(
              onPressed: _openAddTransaction,
              tooltip: 'Thêm giao dịch',
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Tài chính',
          ),
        ],
      ),
    );
  }
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage();

  @override
  Widget build(BuildContext context) {
    return const StatisticsPage();
  }
}

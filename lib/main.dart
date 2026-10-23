import 'package:flutter/material.dart';

import 'screens/main_navigation_page.dart';

void main() {
  runApp(const PersonalExpenseApp());
}

class PersonalExpenseApp extends StatelessWidget {
  const PersonalExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Expense AI',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF173B67),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF173B67),
              secondary: const Color(0xFF16856B),
              surface: Colors.white,
            ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F7FB),
          foregroundColor: Color(0xFF173B67),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
      ),

      home: const MainNavigationPage(),
    );
  }
}

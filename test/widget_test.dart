import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_ai/screens/main_navigation_page.dart';

void main() {
  testWidgets('Ứng dụng hiển thị thanh điều hướng chính', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationPage()));

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
    expect(find.text('Tài chính'), findsOneWidget);

    expect(find.text('Quét hóa đơn'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

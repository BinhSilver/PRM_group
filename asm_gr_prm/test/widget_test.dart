import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asm_gr_prm/main.dart';
import 'package:asm_gr_prm/providers/theme_provider.dart';
import 'package:asm_gr_prm/providers/transaction_provider.dart';
import 'package:asm_gr_prm/providers/user_provider.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  ThemeProvider? themeProvider,
  UserProvider? userProvider,
  TransactionProvider? transactionProvider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider ?? ThemeProvider()),
        ChangeNotifierProvider(create: (_) => userProvider ?? UserProvider()),
        ChangeNotifierProvider(
          create: (_) => transactionProvider ?? TransactionProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App shell shows home screen', (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Số dư hiện tại'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens placeholder modules', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Giao dịch').last);
    await tester.pumpAndSettle();
    expect(find.text('Danh sách giao dịch'), findsOneWidget);

    await tester.tap(find.text('Thống kê').last);
    await tester.pumpAndSettle();
    expect(find.text('Thống kê tài chính'), findsOneWidget);

    await tester.tap(find.text('Ngân sách').last);
    await tester.pumpAndSettle();
    expect(find.text('Quản lý ngân sách'), findsOneWidget);
  });

  testWidgets('Profile inline edit updates display name', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Hồ sơ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sửa hồ sơ'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Codex Tester');
    final saveButton = find.widgetWithText(ElevatedButton, 'Lưu');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Codex Tester'), findsWidgets);
    expect(find.text('Cập nhật hồ sơ thành công'), findsOneWidget);
  });

  testWidgets('Settings toggles dark mode', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await _pumpApp(tester, themeProvider: themeProvider);

    expect(themeProvider.isDarkMode, isFalse);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsWidgets);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(themeProvider.isDarkMode, isTrue);
  });
}

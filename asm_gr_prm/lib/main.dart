import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'database/database_initializer.dart';
import 'database/test_data_seeder.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_screen.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  final defaultUser = await DatabaseInitializer.initialize();
  await TestDataSeeder.seedIfEmpty(defaultUser.id);

  final userProvider = UserProvider();
  await userProvider.loadUser(defaultUser);

  final transactionProvider = TransactionProvider();
  await transactionProvider.fetchTransactions(defaultUser.id);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => transactionProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'spending_jars_screen.dart';
import 'statistics_screen.dart';
import 'transaction_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onTabSelected: _changeTab),
    const TransactionListScreen(),
    const StatisticsScreen(),
    BudgetScreen(onOpenSpendingJars: () => _changeTab(4)),
    const SpendingJarsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Trang chủ',
    'Giao dịch',
    'Thống kê',
    'Ngân sách',
    'Hũ chi tiêu',
    'Hồ sơ',
  ];

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _changeTab,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 25),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Giao dịch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_rounded),
                label: 'Thống kê',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Ngân sách',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.savings_rounded),
                label: 'Hũ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

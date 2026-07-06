import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/settings_screen.dart';
import '../utils/app_constants.dart';

class AppDrawer extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;

  const AppDrawer({super.key, this.onTabSelected});

  void _selectTab(BuildContext context, int index) {
    Navigator.of(context).pop();
    onTabSelected?.call(index);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (!context.mounted || result != true) return;
    context.read<UserProvider>().logout();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Người dùng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user?.username ?? 'guest'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Trang chủ',
                    onTap: () => _selectTab(context, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Giao dịch',
                    onTap: () => _selectTab(context, 1),
                  ),
                  _DrawerItem(
                    icon: Icons.pie_chart_rounded,
                    title: 'Thống kê',
                    onTap: () => _selectTab(context, 2),
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Ngân sách',
                    onTap: () => _selectTab(context, 3),
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Hồ sơ',
                    onTap: () => _selectTab(context, 4),
                  ),
                  const Divider(height: 24),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt',
                    onTap: () => _openSettings(context),
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/profile_actions.dart';
import '../widgets/common_card.dart';
import '../widgets/section_title.dart';
import '../widgets/setting_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showAbout(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giới thiệu'),
        content: const Text(
          '${AppConstants.appName} giúp người dùng theo dõi tài chính cá nhân. '
          'Các module nghiệp vụ sẽ được nhóm tích hợp sau.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'Giao diện',
                subtitle: 'Tùy chỉnh cách hiển thị của app',
              ),
              CommonCard(
                child: SettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Chế độ tối',
                  subtitle: 'Lưu lựa chọn giao diện',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.toggleTheme,
                  ),
                  onTap: () =>
                      themeProvider.toggleTheme(!themeProvider.isDarkMode),
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Tài khoản'),
              CommonCard(
                child: Column(
                  children: [
                    SettingTile(
                      icon: Icons.person_rounded,
                      title: 'Tên hiển thị',
                      subtitle: user?.displayName ?? 'Người dùng',
                    ),
                    const Divider(height: 8),
                    SettingTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'Username',
                      subtitle: '@${user?.username ?? 'guest'}',
                    ),
                    const Divider(height: 8),
                    SettingTile(
                      icon: Icons.lock_rounded,
                      title: 'Đổi mật khẩu',
                      subtitle: 'Sẽ được tích hợp sau',
                      onTap: () =>
                          ProfileActions.showChangePasswordPlaceholder(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Ứng dụng'),
              CommonCard(
                child: Column(
                  children: [
                    const SettingTile(
                      icon: Icons.wallet_rounded,
                      title: 'Tên app',
                      subtitle: AppConstants.appName,
                    ),
                    const Divider(height: 8),
                    const SettingTile(
                      icon: Icons.info_rounded,
                      title: 'Version',
                      subtitle: AppConstants.appVersion,
                    ),
                    const Divider(height: 8),
                    SettingTile(
                      icon: Icons.favorite_rounded,
                      title: 'Giới thiệu',
                      subtitle:
                          'Ứng dụng quản lý thu chi cá nhân với giao diện Pink Wallet Clean UI.',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/common_card.dart';
import '../widgets/section_title.dart';
import '../widgets/setting_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var obscureOld = true;
    var obscureNew = true;
    var obscureConfirm = true;
    var isLoading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: primaryColor),
                const SizedBox(width: 10),
                const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    controller: oldCtrl,
                    label: 'Mật khẩu hiện tại',
                    obscure: obscureOld,
                    onToggleObscure: () =>
                        setDialogState(() => obscureOld = !obscureOld),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Vui lòng nhập' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: newCtrl,
                    label: 'Mật khẩu mới',
                    obscure: obscureNew,
                    onToggleObscure: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập';
                      }
                      if (value.length < 6) return 'Ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: confirmCtrl,
                    label: 'Xác nhận mật khẩu mới',
                    obscure: obscureConfirm,
                    onToggleObscure: () =>
                        setDialogState(() => obscureConfirm = !obscureConfirm),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập';
                      }
                      if (value != newCtrl.text) return 'Không khớp';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isLoading = true);

                        final error = await context
                            .read<UserProvider>()
                            .changePassword(
                              oldPassword: oldCtrl.text,
                              newPassword: newCtrl.text,
                            );

                        if (!ctx.mounted) return;
                        Navigator.of(dialogContext).pop();

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? 'Đổi mật khẩu thành công!'),
                            backgroundColor: error == null
                                ? null
                                : AppColors.expense,
                          ),
                        );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận'),
              ),
            ],
          ),
        );
      },
    );

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  TextFormField _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      validator: validator,
    );
  }

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
                      subtitle: 'Cập nhật mật khẩu đăng nhập',
                      onTap: () => _showChangePasswordDialog(context),
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

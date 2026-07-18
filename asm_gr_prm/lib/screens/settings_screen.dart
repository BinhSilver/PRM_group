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
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );

    if (!context.mounted || changed != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await context.read<UserProvider>().changePassword(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorText = error;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _PasswordField(
                controller: _oldCtrl,
                label: 'Mật khẩu hiện tại',
                obscure: _obscureOld,
                enabled: !_isLoading,
                onToggleObscure: () =>
                    setState(() => _obscureOld = !_obscureOld),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập' : null,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _newCtrl,
                label: 'Mật khẩu mới',
                obscure: _obscureNew,
                enabled: !_isLoading,
                onToggleObscure: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập';
                  }
                  if (value.length < 6) return 'Ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu mới',
                obscure: _obscureConfirm,
                enabled: !_isLoading,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập';
                  }
                  if (value != _newCtrl.text) return 'Không khớp';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
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
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.enabled,
    required this.onToggleObscure,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: enabled ? onToggleObscure : null,
        ),
      ),
      validator: validator,
    );
  }
}

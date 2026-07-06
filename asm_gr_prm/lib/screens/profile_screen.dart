import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/common_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/section_title.dart';
import '../widgets/setting_tile.dart';
import 'auth/login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  String? _nameErrorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditName(String currentName) {
    setState(() {
      _nameController.text = currentName;
      _nameErrorText = null;
      _isEditingName = true;
    });
  }

  void _cancelEditName() {
    setState(() {
      _isEditingName = false;
      _nameErrorText = null;
    });
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _nameErrorText = 'Tên hiển thị không được rỗng');
      return;
    }

    await context.read<UserProvider>().updateDisplayName(newName);
    if (!mounted) return;

    setState(() {
      _isEditingName = false;
      _nameErrorText = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cập nhật hồ sơ thành công')));
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: primaryColor),
              const SizedBox(width: 10),
              const Text('Đổi mật khẩu',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                  controller: oldCtrl,
                  label: 'Mật khẩu hiện tại',
                  obscure: obscureOld,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onToggleObscure: () =>
                      setDialogState(() => obscureOld = !obscureOld),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập' : null,
                ),
                const SizedBox(height: 12),
                _buildDialogField(
                  controller: newCtrl,
                  label: 'Mật khẩu mới',
                  obscure: obscureNew,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onToggleObscure: () =>
                      setDialogState(() => obscureNew = !obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập';
                    if (v.length < 6) return 'Ít nhất 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildDialogField(
                  controller: confirmCtrl,
                  label: 'Xác nhận mật khẩu mới',
                  obscure: obscureConfirm,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onToggleObscure: () =>
                      setDialogState(() => obscureConfirm = !obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập';
                    if (v != newCtrl.text) return 'Không khớp';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);

                      final error =
                          await context.read<UserProvider>().changePassword(
                                oldPassword: oldCtrl.text,
                                newPassword: newCtrl.text,
                              );

                      if (!ctx.mounted) return;
                      Navigator.of(dialogContext).pop();

                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.expense,
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đổi mật khẩu thành công!'),
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  TextFormField _buildDialogField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    final subColor = isDark ? AppColors.darkTextSub : AppColors.lightTextSub;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
          color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: subColor),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: subColor,
            size: 18,
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2F1B38) : const Color(0xFFFDF0F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEE0F0)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (!context.mounted || result != true) return;

    await context.read<UserProvider>().logout();

    if (!context.mounted) return;

    // Điều hướng về màn hình đăng nhập, xóa toàn bộ stack
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final displayName = user?.displayName ?? 'Người dùng';
    final createdAt = user?.createdAt;
    final createdDate = createdAt == null
        ? 'Chưa có thông tin'
        : '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              user: user,
              onEditProfile: () => _startEditName(displayName),
              onOpenSettings: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            if (_isEditingName) ...[
              const SizedBox(height: 14),
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chỉnh sửa tên hiển thị',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Tên hiển thị',
                        errorText: _nameErrorText,
                      ),
                      onSubmitted: (_) => _saveDisplayName(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelEditName,
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveDisplayName,
                            child: const Text('Lưu'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            const SectionTitle(title: 'Thông tin tài khoản'),
            CommonCard(
              child: Column(
                children: [
                  SettingTile(
                    icon: Icons.badge_rounded,
                    title: 'Tên hiển thị',
                    subtitle: displayName,
                    trailing: IconButton(
                      tooltip: 'Chỉnh sửa',
                      onPressed: () => _startEditName(displayName),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    onTap: () => _startEditName(displayName),
                  ),
                  const Divider(height: 8),
                  SettingTile(
                    icon: Icons.alternate_email_rounded,
                    title: 'Username',
                    subtitle: '@${user?.username ?? 'guest'}',
                  ),
                  const Divider(height: 8),
                  SettingTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Ngày tạo tài khoản',
                    subtitle: createdDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Tùy chọn'),
            CommonCard(
              child: Column(
                children: [
                  SettingTile(
                    icon: Icons.edit_rounded,
                    title: 'Chỉnh sửa hồ sơ',
                    subtitle: 'Cập nhật tên hiển thị',
                    onTap: () => _startEditName(displayName),
                  ),
                  const Divider(height: 8),
                  SettingTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Đổi mật khẩu',
                    subtitle: 'Thay đổi mật khẩu đăng nhập',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 8),
                  SettingTile(
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt',
                    subtitle: 'Chế độ tối và thông tin ứng dụng',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const Divider(height: 8),
                  SettingTile(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    subtitle: 'Xác nhận trước khi đăng xuất',
                    iconColor: AppColors.expense,
                    titleColor: AppColors.expense,
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

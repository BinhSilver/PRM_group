import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isPickingAvatar = false;
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

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar) return;

    setState(() => _isPickingAvatar = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final avatarBase64 = base64Encode(bytes);

      if (!mounted) return;
      await context.read<UserProvider>().updateAvatarBase64(avatarBase64);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chọn ảnh. Vui lòng thử lại.'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingAvatar = false);
      }
    }
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
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
              avatarBase64: userProvider.avatarBase64,
              onEditProfile: () => _startEditName(displayName),
              onChangeAvatar: _pickAvatar,
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
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt',
                    subtitle: 'Chế độ tối và thông tin ứng dụng',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

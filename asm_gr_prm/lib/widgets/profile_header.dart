import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'common_card.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final String? avatarBase64;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangeAvatar;

  const ProfileHeader({
    super.key,
    required this.user,
    this.avatarBase64,
    this.onEditProfile,
    this.onChangeAvatar,
  });

  ImageProvider? _avatarImageProvider() {
    final data = avatarBase64;
    if (data == null || data.isEmpty) return null;

    try {
      return MemoryImage(base64Decode(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Người dùng';
    final username = user?.username ?? 'guest';
    final createdAt = user?.createdAt;
    final avatarImage = _avatarImageProvider();
    final createdDate = createdAt == null
        ? 'Chưa có thông tin'
        : 'Tạo tài khoản: ${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return CommonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 116,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.14),
                      AppColors.momoTint,
                      AppColors.secondary.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 22,
                      top: 18,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent.withValues(alpha: 0.24),
                        size: 42,
                      ),
                    ),
                    Positioned(
                      right: 70,
                      bottom: 12,
                      child: Icon(
                        Icons.savings_rounded,
                        color: AppColors.primary.withValues(alpha: 0.18),
                        size: 54,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                bottom: -42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onChangeAvatar,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardTheme.color,
                          border: Border.all(
                            color:
                                Theme.of(context).cardTheme.color ??
                                Colors.white,
                            width: 6,
                          ),
                        ),
                        child: ClipOval(
                          child: avatarImage == null
                              ? Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                )
                              : Image(
                                  image: avatarImage,
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Tooltip(
                        message: 'Cập nhật ảnh đại diện',
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Material(
                            color: Theme.of(context).cardTheme.color,
                            shape: const CircleBorder(),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.16),
                            child: InkResponse(
                              onTap: onChangeAvatar,
                              radius: 24,
                              containedInkWell: true,
                              customBorder: const CircleBorder(),
                              child: Icon(
                                Icons.photo_camera_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 54),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  createdDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Sửa hồ sơ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

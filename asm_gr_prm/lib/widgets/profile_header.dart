import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'common_card.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onEditProfile;
  final VoidCallback? onOpenSettings;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onEditProfile,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Người dùng';
    final username = user?.username ?? 'guest';
    final createdAt = user?.createdAt;
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
                      AppColors.primary.withOpacity(0.18),
                      AppColors.secondary.withOpacity(0.12),
                      AppColors.accent.withOpacity(0.10),
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
                        color: AppColors.accent.withOpacity(0.24),
                        size: 42,
                      ),
                    ),
                    Positioned(
                      right: 70,
                      bottom: 12,
                      child: Icon(
                        Icons.savings_rounded,
                        color: AppColors.primary.withOpacity(0.18),
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
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(
                          color:
                              Theme.of(context).cardTheme.color ?? Colors.white,
                          width: 6,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 6,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: onEditProfile,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
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
                    IconButton(
                      tooltip: 'Cài đặt',
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings_rounded),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.settings_rounded, size: 18),
                        label: const Text('Cài đặt'),
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

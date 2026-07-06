import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/app_constants.dart';

class SkeletonLoading extends StatelessWidget {
  final int itemCount;

  const SkeletonLoading({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurface : Colors.grey[300]!;
    final highlightColor = isDark
        ? AppColors.darkBorder
        : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (_) => const _SkeletonRow()),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(width: 100, height: 12, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 80, height: 16, color: Colors.white),
        ],
      ),
    );
  }
}
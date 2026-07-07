import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  const CommonCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

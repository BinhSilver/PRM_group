import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

enum TimeFilterType { all, today, week, month, year }

class TimeFilterWidget extends StatelessWidget {
  final TimeFilterType selectedFilter;
  final ValueChanged<TimeFilterType> onFilterChanged;

  const TimeFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(context, 'Tất cả', TimeFilterType.all),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Hôm nay', TimeFilterType.today),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Tuần này', TimeFilterType.week),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Tháng này', TimeFilterType.month),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Năm nay', TimeFilterType.year),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    TimeFilterType type,
  ) {
    final isSelected = selectedFilter == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightTextSub;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onFilterChanged(type);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : borderColor.withValues(alpha: 0.35),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class SortOption {
  final String label;
  final String sortBy;
  final String sortOrder;

  SortOption(this.label, this.sortBy, this.sortOrder);
}

class SortDropdownWidget extends StatelessWidget {
  final String currentSortBy;
  final String currentSortOrder;
  final void Function(String, String) onSortChanged;

  final List<SortOption> options = [
    SortOption('Mới nhất', 'date', 'DESC'),
    SortOption('Cũ nhất', 'date', 'ASC'),
    SortOption('Số tiền tăng dần', 'amount', 'ASC'),
    SortOption('Số tiền giảm dần', 'amount', 'DESC'),
  ];

  SortDropdownWidget({
    super.key,
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentOption = options.firstWhere(
      (opt) => opt.sortBy == currentSortBy && opt.sortOrder == currentSortOrder,
      orElse: () => options[0],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.sort_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          DropdownButton<SortOption>(
            value: currentOption,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
            items: options.map((SortOption option) {
              return DropdownMenuItem<SortOption>(
                value: option,
                child: Text(option.label),
              );
            }).toList(),
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                onSortChanged(newValue.sortBy, newValue.sortOrder);
              }
            },
          ),
        ],
      ),
    );
  }
}
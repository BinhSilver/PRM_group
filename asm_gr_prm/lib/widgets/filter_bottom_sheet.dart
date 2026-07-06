import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../utils/app_constants.dart';
import 'time_filter_widget.dart';

class FilterBottomSheet extends StatefulWidget {
  final int userId;

  const FilterBottomSheet({super.key, required this.userId});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String? _tempType;
  late TimeFilterType _tempTimeType;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TransactionProvider>();
    _tempType = provider.selectedType;
    _tempTimeType = provider.timeFilterType;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightTextSub;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc lịch sử giao dịch',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Theo thời gian',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterButton('Tất cả', TimeFilterType.all, isTime: true, borderColor: borderColor),
              _buildFilterButton('Hôm nay', TimeFilterType.today, isTime: true, borderColor: borderColor),
              _buildFilterButton('Tuần này', TimeFilterType.week, isTime: true, borderColor: borderColor),
              _buildFilterButton('Tháng này', TimeFilterType.month, isTime: true, borderColor: borderColor),
              _buildFilterButton('Năm nay', TimeFilterType.year, isTime: true, borderColor: borderColor),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Theo loại giao dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterButton('Tất cả', null, isType: true, borderColor: borderColor),
              _buildFilterButton('Thu nhập', 'income', isType: true, borderColor: borderColor),
              _buildFilterButton('Chi tiêu', 'expense', isType: true, borderColor: borderColor),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempType = null;
                      _tempTimeType = TimeFilterType.all;
                    });
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<TransactionProvider>().setFilters(
                      userId: widget.userId,
                      type: _tempType,
                      timeType: _tempTimeType,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String label,
    dynamic value, {
    bool isTime = false,
    bool isType = false,
    required Color borderColor,
  }) {
    bool isSelected = false;
    if (isTime) isSelected = _tempTimeType == value;
    if (isType) isSelected = _tempType == value;

    return InkWell(
      onTap: () {
        setState(() {
          if (isTime) _tempTimeType = value;
          if (isType) _tempType = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
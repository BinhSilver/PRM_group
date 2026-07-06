import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';

import '../widgets/common_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/sort_dropdown_widget.dart';
import '../widgets/transaction_card.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  int _resolveUserId(BuildContext context) {
    return context.read<UserProvider>().currentUser?.id ?? 0;
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thêm giao dịch sẽ được tích hợp sau')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _resolveUserId(context);

    return SafeArea(
      top: false,
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final grouped = _groupTransactionsByMonth(provider.transactions);
          final monthKeys = grouped.keys.toList();

          return RefreshIndicator(
            onRefresh: () => provider.fetchTransactions(userId),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummarySection(context, provider),
                        const SizedBox(height: 22),
                        const SectionTitle(title: 'Danh sách giao dịch'),
                        const SizedBox(height: 8),
                        _buildSearchAndActions(context, userId),
                        SortDropdownWidget(
                          currentSortBy: provider.sortBy,
                          currentSortOrder: provider.sortOrder,
                          onSortChanged: (sortBy, sortOrder) {
                            provider.setSort(userId, sortBy, sortOrder);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverToBoxAdapter(child: SkeletonLoading())
                else if (provider.transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyStateWidget(
                        message:
                            'Chưa có giao dịch nào.\nHãy thêm giao dịch đầu tiên.',
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final month = monthKeys[index];
                      final transactions = grouped[month]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMonthHeader(context, month),
                          CommonCard(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: transactions
                                  .map(
                                    (t) => TransactionCard(
                                      transaction: t,
                                      onTap: () => _showComingSoon(context),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      );
                    }, childCount: monthKeys.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, TransactionProvider provider) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan giao dịch',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            CurrencyFormatter.format(provider.balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Số dư hiện tại',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  title: 'Tổng thu',
                  amount: provider.totalIncome,
                  color: AppColors.income,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  title: 'Tổng chi',
                  amount: provider.totalExpense,
                  color: AppColors.expense,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions(BuildContext context, int userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightTextSub;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (query) => context
                        .read<TransactionProvider>()
                        .setSearchQuery(userId, query),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm giao dịch',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCircleAction(
          context: context,
          icon: Icons.tune_rounded,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FilterBottomSheet(userId: userId),
            );
          },
        ),
        const SizedBox(width: 8),
        _buildCircleAction(
          context: context,
          icon: Icons.add_rounded,
          onTap: () => _showComingSoon(context),
          filled: true,
        ),
      ],
    );
  }

  Widget _buildCircleAction({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightTextSub;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.primary : Theme.of(context).cardTheme.color,
          border: filled ? null : Border.all(color: borderColor.withValues(alpha: 0.35)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, String month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        'Tháng $month',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByMonth(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final t in transactions) {
      final month = DateFormat('M/yyyy').format(t.date);
      grouped.putIfAbsent(month, () => []).add(t);
    }
    return grouped;
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
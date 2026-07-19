import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/spending_jar_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';
import '../widgets/section_title.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback onOpenSpendingJars;

  const BudgetScreen({super.key, required this.onOpenSpendingJars});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<UserProvider>().currentUser;
    if (user == null || _loadedUserId == user.id) return;

    _loadedUserId = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SpendingJarProvider>().loadJars(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final jarProvider = context.watch<SpendingJarProvider>();

    if (user == null || jarProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalBudget = jarProvider.allocatedBudget;
    final spent = jarProvider.totalSpentInJars;
    final remaining = jarProvider.remainingInJars;
    final progress = totalBudget > 0
        ? (spent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => jarProvider.loadJars(user.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetSummaryCard(
                totalBudget: totalBudget,
                spent: spent,
                remaining: remaining,
                progress: progress,
                onOpenSpendingJars: widget.onOpenSpendingJars,
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                title: 'Phân bổ theo hũ',
                subtitle: 'Ngân sách được tính từ các hũ chi tiêu',
              ),
              const SizedBox(height: 12),
              if (jarProvider.jars.isEmpty)
                _EmptyBudgetCard(onOpenSpendingJars: widget.onOpenSpendingJars)
              else
                ...jarProvider.jars.map((jar) {
                  final spent = jarProvider.getSpent(jar);
                  final remaining = jarProvider.getRemaining(jar);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommonCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Color(
                                jar.colorValue,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.savings_rounded,
                              color: Color(jar.colorValue),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jar.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đã dùng ${CurrencyFormatter.format(spent)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(jar.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Còn ${CurrencyFormatter.format(remaining)}',
                                style: TextStyle(
                                  color: remaining < 0
                                      ? AppColors.expense
                                      : AppColors.income,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final double totalBudget;
  final double spent;
  final double remaining;
  final double progress;
  final VoidCallback onOpenSpendingJars;

  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.onOpenSpendingJars,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngân sách còn lại',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tổng hợp từ các hũ chi tiêu',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            CurrencyFormatter.format(remaining),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: remaining < 0 ? AppColors.expense : AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              color: remaining < 0 ? AppColors.expense : AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniBudgetMetric(
                  label: 'Tổng hũ',
                  value: CurrencyFormatter.format(totalBudget),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniBudgetMetric(
                  label: 'Đã dùng',
                  value: CurrencyFormatter.format(spent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenSpendingJars,
              icon: const Icon(Icons.savings_rounded),
              label: const Text('Quản lý hũ chi tiêu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBudgetMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniBudgetMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  final VoidCallback onOpenSpendingJars;

  const _EmptyBudgetCard({required this.onOpenSpendingJars});

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
            child: const Icon(Icons.savings_rounded, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có hũ chi tiêu',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Thêm hũ để bắt đầu phân bổ ngân sách cho từng loại chi tiêu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOpenSpendingJars,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm hũ chi tiêu'),
          ),
        ],
      ),
    );
  }
}

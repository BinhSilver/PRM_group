import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/spending_jar_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_title.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onTabSelected;

  const HomeScreen({super.key, required this.onTabSelected});

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title sẽ được tích hợp sau')));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    final finance = context.watch<TransactionProvider>();
    final jarProvider = context.watch<SpendingJarProvider>();
    final remainingBudget = jarProvider.remainingInJars;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${user?.displayName ?? 'bạn'}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Hôm nay bạn muốn theo dõi gì?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.92),
                    AppColors.secondary.withValues(alpha: 0.84),
                    const Color(0xFFFFD6EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Số dư hiện tại',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    CurrencyFormatter.format(finance.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _OverviewCard(
              totalIncome: finance.totalIncome,
              totalExpense: finance.totalExpense,
              remainingBudget: remainingBudget,
              onTabSelected: onTabSelected,
            ),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Tiện ích nhanh'),
            CommonCard(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8,
                children: [
                  QuickActionCard(
                    icon: Icons.add_card_rounded,
                    title: 'Thêm giao dịch',
                    color: AppColors.primary,
                    onTap: () => onTabSelected(1),
                  ),
                  QuickActionCard(
                    icon: Icons.pie_chart_rounded,
                    title: 'Xem thống kê',
                    color: AppColors.accent,
                    onTap: () => onTabSelected(2),
                  ),
                  QuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Ngân sách',
                    color: AppColors.warning,
                    onTap: () => onTabSelected(4),
                  ),
                  QuickActionCard(
                    icon: Icons.savings_rounded,
                    title: 'Hũ chi tiêu',
                    color: AppColors.income,
                    onTap: () => onTabSelected(4),
                  ),
                  QuickActionCard(
                    icon: Icons.apps_rounded,
                    title: 'Xem thêm',
                    color: Colors.grey,
                    onTap: () => _showComingSoon(context, 'Tiện ích mở rộng'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _JarBudgetAlertCard(
              jarProvider: jarProvider,
              onOpenSpendingJars: () => onTabSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _JarBudgetAlertCard extends StatelessWidget {
  final SpendingJarProvider jarProvider;
  final VoidCallback onOpenSpendingJars;

  const _JarBudgetAlertCard({
    required this.jarProvider,
    required this.onOpenSpendingJars,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jars = jarProvider.jars;

    if (jars.isEmpty) {
      return _AlertShell(
        icon: Icons.savings_rounded,
        iconColor: AppColors.primary,
        title: 'Thông báo hũ chi tiêu',
        message: 'Bạn chưa có hũ nào để theo dõi ngân sách.',
        suggestion:
            'Tạo hũ cho từng loại chi tiêu để app nhắc bạn khi sắp hết tiền.',
        actionText: 'Tạo hũ',
        onTap: onOpenSpendingJars,
      );
    }

    final overJars = jars
        .where((jar) => jarProvider.getRemaining(jar) < 0)
        .toList();
    if (overJars.isNotEmpty) {
      overJars.sort(
        (a, b) =>
            jarProvider.getRemaining(a).compareTo(jarProvider.getRemaining(b)),
      );
      final jar = overJars.first;
      final overAmount = jarProvider.getRemaining(jar).abs();
      return _AlertShell(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.expense,
        title: 'Hũ ${jar.name} đã vượt mức',
        message: 'Bạn đã dùng vượt ${CurrencyFormatter.format(overAmount)}.',
        suggestion:
            'Nên giảm chi ở nhóm này hoặc điều chỉnh lại số tiền phân bổ cho hũ.',
        actionText: 'Kiểm tra hũ',
        onTap: onOpenSpendingJars,
      );
    }

    final lowJars =
        jars.where((jar) {
          final remaining = jarProvider.getRemaining(jar);
          return jar.amount > 0 && remaining <= jar.amount * 0.2;
        }).toList()..sort(
          (a, b) => jarProvider
              .getRemaining(a)
              .compareTo(jarProvider.getRemaining(b)),
        );

    if (lowJars.isNotEmpty) {
      final jar = lowJars.first;
      final remaining = jarProvider.getRemaining(jar);
      return _AlertShell(
        icon: Icons.notifications_active_rounded,
        iconColor: AppColors.warning,
        title: 'Hũ ${jar.name} sắp hết',
        message: 'Hũ này còn ${CurrencyFormatter.format(remaining)}.',
        suggestion:
            'Hãy ưu tiên khoản cần thiết và hạn chế phát sinh thêm trong nhóm này.',
        actionText: 'Xem chi tiết',
        onTap: onOpenSpendingJars,
      );
    }

    return _AlertShell(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.income,
      title: 'Ngân sách đang ổn',
      message: 'Các hũ chi tiêu vẫn còn trong mức an toàn.',
      suggestion:
          'Tiếp tục ghi lại giao dịch đều đặn để giữ thói quen chi tiêu hợp lý.',
      actionText: 'Xem hũ',
      onTap: onOpenSpendingJars,
      titleStyle: theme.textTheme.titleMedium,
    );
  }
}

class _AlertShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String suggestion;
  final String actionText;
  final VoidCallback onTap;
  final TextStyle? titleStyle;

  const _AlertShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.suggestion,
    required this.actionText,
    required this.onTap,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CommonCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        titleStyle?.copyWith(fontWeight: FontWeight.w800) ??
                        const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestion,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double remainingBudget;
  final ValueChanged<int> onTabSelected;

  const _OverviewCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.remainingBudget,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withValues(alpha: 0.88),
                ]
              : [Colors.white, const Color(0xFFFFF0F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onTabSelected(2), // Chuyển sang tab Thống kê
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng quan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_up_rounded,
                  title: 'Tổng thu',
                  amount: CurrencyFormatter.format(totalIncome),
                  amountColor: AppColors.income,
                  onTap: () => onTabSelected(1), // Chuyển sang tab Giao dịch
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_down_rounded,
                  title: 'Tổng chi',
                  amount: CurrencyFormatter.format(totalExpense),
                  amountColor: AppColors.expense,
                  onTap: () => onTabSelected(1), // Chuyển sang tab Giao dịch
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _OverviewMetricBox(
            icon: Icons.savings_rounded,
            title: 'Ngân sách còn lại',
            amount: CurrencyFormatter.format(remainingBudget),
            amountColor: AppColors.warning,
            compact: true,
            onTap: () => onTabSelected(4), // Chuyển sang tab Hũ chi tiêu
          ),
        ],
      ),
    );
  }
}

class _OverviewMetricBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final Color amountColor;
  final bool compact;
  final VoidCallback? onTap;

  const _OverviewMetricBox({
    required this.icon,
    required this.title,
    required this.amount,
    required this.amountColor,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = isDark
        ? amountColor.withValues(alpha: 0.12)
        : amountColor.withValues(alpha: 0.07);
    final borderColor = amountColor.withValues(alpha: isDark ? 0.24 : 0.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 54 : 62),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: compact
              ? [
                  Row(
                    children: [
                      _MetricIcon(
                        icon: icon,
                        color: amountColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ]
              : [
                  Row(
                    children: [
                      _MetricIcon(
                        icon: icon,
                        color: amountColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ],
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}

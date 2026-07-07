import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
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
    final user = context.watch<UserProvider>().currentUser;

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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE85AA8),
                    Color(0xFFD75EC4),
                    Color(0xFFB46EE6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
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
                    '0đ',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _OverviewCard(),
            const SizedBox(height: 22),
            const SectionTitle(title: 'Tiện ích nhanh'),
            CommonCard(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 4,
                mainAxisSpacing: 8,
                childAspectRatio: 0.72,
                children: [
                  QuickActionCard(
                    icon: Icons.add_card_rounded,
                    title: 'Thêm\ngiao dịch',
                    color: AppColors.primary,
                    onTap: () => onTabSelected(1),
                  ),
                  QuickActionCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Ghi\nthu nhập',
                    color: AppColors.income,
                    onTap: () => onTabSelected(1),
                  ),
                  QuickActionCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Ghi\nchi tiêu',
                    color: AppColors.expense,
                    onTap: () => onTabSelected(1),
                  ),
                  QuickActionCard(
                    icon: Icons.pie_chart_rounded,
                    title: 'Xem\nthống kê',
                    color: AppColors.accent,
                    onTap: () => onTabSelected(2),
                  ),
                  QuickActionCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Ngân\nsách',
                    color: AppColors.warning,
                    onTap: () => onTabSelected(3),
                  ),
                  QuickActionCard(
                    icon: Icons.person_rounded,
                    title: 'Hồ\nsơ',
                    color: AppColors.secondary,
                    onTap: () => onTabSelected(4),
                  ),
                  QuickActionCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'Gợi ý\nhôm nay',
                    color: const Color(0xFF14B8A6),
                    onTap: () => _showComingSoon(context, 'Gợi ý tài chính'),
                  ),
                  QuickActionCard(
                    icon: Icons.apps_rounded,
                    title: 'Xem\nthêm',
                    color: Colors.grey,
                    onTap: () => _showComingSoon(context, 'Tiện ích mở rộng'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CommonCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gợi ý hôm nay:',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hãy ghi lại chi tiêu ngay sau khi thanh toán để kiểm soát tài chính tốt hơn.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withOpacity(0.88),
                ]
              : [Colors.white, const Color(0xFFFFF0F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primary.withOpacity(0.08),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng quan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_up_rounded,
                  title: 'Tổng thu',
                  amount: '0đ',
                  amountColor: AppColors.income,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMetricBox(
                  icon: Icons.trending_down_rounded,
                  title: 'Tổng chi',
                  amount: '0đ',
                  amountColor: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _OverviewMetricBox(
            icon: Icons.savings_rounded,
            title: 'Ngân sách còn lại',
            amount: '0đ',
            amountColor: AppColors.warning,
            compact: true,
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

  const _OverviewMetricBox({
    required this.icon,
    required this.title,
    required this.amount,
    required this.amountColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = isDark
        ? amountColor.withOpacity(0.12)
        : amountColor.withOpacity(0.07);
    final borderColor = amountColor.withOpacity(isDark ? 0.24 : 0.14);

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 64 : 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: amountColor, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(
                    isDark ? 0.18 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final txProvider = context.watch<TransactionProvider>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final income = txProvider.totalIncome;
    final expense = txProvider.totalExpense;
    final balance = txProvider.balance;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Tổng quan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // 3 Summary cards - đẹp, chuyên nghiệp
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Tổng thu',
                    amount: income,
                    color: AppColors.income,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Tổng chi',
                    amount: expense,
                    color: AppColors.expense,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Số dư',
                    amount: balance,
                    color: AppColors.primary,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Phân bổ chi tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Donut chart + Legend
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(txProvider),
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend chỉ Thu & Chi (Số dư không phải là loại giao dịch)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Thu', AppColors.income),
                const SizedBox(width: 28),
                _buildLegendItem('Chi', AppColors.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Card tổng quan mới - bo góc mềm, shadow nhẹ, padding đẹp
  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(TransactionProvider provider) {
    // Simple: chỉ phân loại theo type (income/expense) cho demo
    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final total = income + expense;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.green,
        value: income,
        title: 'Thu',
        radius: 48,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: expense,
        title: 'Chi',
        radius: 48,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildSummaryCard(
                        context,
                        title: 'Tổng thu',
                        amount: income,
                        color: AppColors.income,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildSummaryCard(
                        context,
                        title: 'Tổng chi',
                        amount: expense,
                        color: AppColors.expense,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _buildSummaryCard(
                        context,
                        title: 'Số dư',
                        amount: balance,
                        color: AppColors.primary,
                        icon: Icons.account_balance_wallet_rounded,
                        compact: true,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Phân bổ chi tiêu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            CommonCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: _DonutBreakdownChart(
                      slices: _buildChartSlices(txProvider),
                    ),
                  ),
                  const SizedBox(height: 8),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 64 : 82),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 10,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.24 : 0.16),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: compact
          ? Row(
              children: [
                _SummaryIcon(icon: icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryText(
                    title: title,
                    amount: amount,
                    color: color,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withValues(alpha: 0.58),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SummaryIcon(icon: icon, color: color),
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
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(amount),
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<_ChartSlice> _buildChartSlices(TransactionProvider provider) {
    final income = provider.totalIncome;
    final expense = provider.totalExpense;
    final total = income + expense;

    if (total == 0) {
      return [
        const _ChartSlice(
          label: 'Chưa có dữ liệu',
          value: 1,
          color: AppColors.lightBorder,
          icon: Icons.pie_chart_outline_rounded,
        ),
      ];
    }

    return [
      _ChartSlice(
        label: 'Thu',
        value: income,
        color: AppColors.income,
        icon: Icons.trending_up_rounded,
      ),
      _ChartSlice(
        label: 'Chi',
        value: expense,
        color: AppColors.expense,
        icon: Icons.trending_down_rounded,
      ),
    ];
  }
}

class _SummaryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SummaryIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryText({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
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
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              CurrencyFormatter.format(amount),
              maxLines: 1,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartSlice {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _DonutBreakdownChart extends StatelessWidget {
  final List<_ChartSlice> slices;

  const _DonutBreakdownChart({required this.slices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPaint(
      painter: _DonutBreakdownPainter(
        slices: slices,
        textColor: theme.colorScheme.onSurfaceVariant,
        surfaceColor: theme.colorScheme.surface,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DonutBreakdownPainter extends CustomPainter {
  final List<_ChartSlice> slices;
  final Color textColor;
  final Color surfaceColor;

  _DonutBreakdownPainter({
    required this.slices,
    required this.textColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) * 0.28;
    final strokeWidth = radius * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.lightBorder.withValues(alpha: 0.48);
    canvas.drawCircle(center, radius, basePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2;
      ringPaint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweep, false, ringPaint);
      _drawOutsideLabel(
        canvas: canvas,
        size: size,
        center: center,
        radius: radius,
        angle: startAngle + sweep / 2,
        slice: slice,
        percent: slice.value / total,
      );
      startAngle += sweep;
    }

    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = surfaceColor;
    canvas.drawCircle(center, radius - strokeWidth * 0.68, holePaint);
  }

  void _drawOutsideLabel({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double radius,
    required double angle,
    required _ChartSlice slice,
    required double percent,
  }) {
    final isRight = math.cos(angle) >= 0;
    final anchor = Offset(
      center.dx + math.cos(angle) * (radius + 5),
      center.dy + math.sin(angle) * (radius + 5),
    );
    final elbow = Offset(
      center.dx + math.cos(angle) * (radius + 25),
      center.dy + math.sin(angle) * (radius + 25),
    );
    final labelX = isRight ? size.width - 82 : 14.0;
    final lineEnd = Offset(isRight ? labelX - 10 : labelX + 72, elbow.dy);

    final dashPaint = Paint()
      ..color = AppColors.lightTextSub.withValues(alpha: 0.24)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, anchor, elbow, dashPaint);
    _drawDashedLine(canvas, elbow, lineEnd, dashPaint);

    final percentText = '${(percent * 100).toStringAsFixed(0)}%';
    final percentPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: String.fromCharCode(slice.icon.codePoint),
            style: TextStyle(
              color: slice.color,
              fontSize: 15,
              fontFamily: slice.icon.fontFamily,
              package: slice.icon.fontPackage,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: percentText,
            style: TextStyle(
              color: slice.color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 82);

    final labelPainter = TextPainter(
      text: TextSpan(
        text: slice.label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 82);

    final labelTop = (elbow.dy - 19).clamp(4.0, size.height - 44);
    percentPainter.paint(canvas, Offset(labelX, labelTop));
    labelPainter.paint(canvas, Offset(labelX, labelTop + 22));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final distance = (end - start).distance;
    if (distance == 0) return;

    final direction = (end - start) / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final segmentStart = start + direction * drawn;
      final segmentEnd =
          start + direction * math.min(drawn + dashWidth, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutBreakdownPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.textColor != textColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

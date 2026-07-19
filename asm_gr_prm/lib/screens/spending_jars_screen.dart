import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/spending_jar_model.dart';
import '../providers/spending_jar_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';
import '../widgets/section_title.dart';

class SpendingJarsScreen extends StatefulWidget {
  const SpendingJarsScreen({super.key});

  @override
  State<SpendingJarsScreen> createState() => _SpendingJarsScreenState();
}

class _SpendingJarsScreenState extends State<SpendingJarsScreen> {
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
              _JarsHeroCard(
                jarCount: jarProvider.jars.length,
                month: jarProvider.selectedMonth,
                monthlyBudget: jarProvider.monthlyBudget,
                allocatedBudget: jarProvider.allocatedBudget,
                remainingInJars: jarProvider.remainingInJars,
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                title: 'Hũ chi tiêu',
                subtitle: 'Chia ngân sách tổng thành từng hũ nhỏ',
              ),
              const SizedBox(height: 12),
              if (jarProvider.jars.isEmpty)
                _EmptyJarsCard(onCreate: () => _showJarDialog(context))
              else
                ...jarProvider.jars.map(
                  (jar) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JarCard(
                      jar: jar,
                      spent: jarProvider.getSpent(jar),
                      remaining: jarProvider.getRemaining(jar),
                      progress: jarProvider.getProgress(jar),
                      categoryName: _categoryName(
                        jarProvider.expenseCategories,
                        jar.categoryId,
                      ),
                      onEdit: () => _showJarDialog(context, jar: jar),
                      onDelete: jar.id == null
                          ? null
                          : () => _confirmDelete(context, jar.id!, user.id),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              _CreateJarCard(onTap: () => _showJarDialog(context)),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryName(List<CategoryModel> categories, int? categoryId) {
    if (categoryId == null) return 'Chưa chọn danh mục';
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Danh mục đã xóa';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    int jarId,
    int userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hũ chi tiêu'),
        content: const Text('Bạn có chắc muốn xóa hũ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;
    await context.read<SpendingJarProvider>().deleteJar(jarId, userId);
  }

  Future<void> _showJarDialog(
    BuildContext context, {
    SpendingJarModel? jar,
  }) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final jarProvider = context.read<SpendingJarProvider>();
    final nameCtrl = TextEditingController(text: jar?.name ?? '');
    final amountCtrl = TextEditingController(
      text: jar == null ? '' : jar.amount.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final categoryIds = jarProvider.expenseCategories
        .map((category) => category.id)
        .whereType<int>()
        .toSet();
    var selectedCategoryId = categoryIds.contains(jar?.categoryId)
        ? jar?.categoryId
        : null;
    var selectedColor = jar?.colorValue ?? AppColors.primary.toARGB32();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(jar == null ? 'Tạo hũ mới' : 'Sửa hũ chi tiêu'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Tên hũ'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên hũ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền phân bổ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Số tiền phải lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Loại chi tiêu của hũ',
                    ),
                    items: jarProvider.expenseCategories.isEmpty
                        ? const [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Chưa có loại chi tiêu'),
                            ),
                          ]
                        : jarProvider.expenseCategories
                              .where((category) => category.id != null)
                              .map(
                                (category) => DropdownMenuItem<int?>(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                    onChanged: jarProvider.expenseCategories.isEmpty
                        ? null
                        : (value) {
                            setDialogState(() => selectedCategoryId = value);
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Vui lòng chọn loại chi tiêu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Màu hũ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _jarColors.map((color) {
                      final selected = selectedColor == color.toARGB32();
                      return InkWell(
                        onTap: () {
                          setDialogState(
                            () => selectedColor = color.toARGB32(),
                          );
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final amount = double.parse(amountCtrl.text);
                      final categoryId = selectedCategoryId;
                      if (categoryId == null) {
                        setDialogState(() => isSaving = false);
                        return;
                      }
                      final error = jar == null
                          ? await jarProvider.createJar(
                              userId: user.id,
                              name: nameCtrl.text,
                              amount: amount,
                              categoryId: categoryId,
                              colorValue: selectedColor,
                            )
                          : await jarProvider.updateJar(
                              userId: user.id,
                              jar: jar,
                              name: nameCtrl.text,
                              amount: amount,
                              categoryId: categoryId,
                              colorValue: selectedColor,
                            );

                      if (!ctx.mounted) return;
                      if (error != null) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

const _jarColors = [
  AppColors.primary,
  AppColors.warning,
  AppColors.income,
  Color(0xFF38BDF8),
  Color(0xFF8B5CF6),
];

class _JarsHeroCard extends StatelessWidget {
  final int jarCount;
  final String month;
  final double monthlyBudget;
  final double allocatedBudget;
  final double remainingInJars;

  const _JarsHeroCard({
    required this.jarCount,
    required this.month,
    required this.monthlyBudget,
    required this.allocatedBudget,
    required this.remainingInJars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            AppColors.secondary.withValues(alpha: 0.76),
            const Color(0xFFFFD8EC),
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
              Icon(Icons.savings_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Ngân sách theo hũ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(monthlyBudget),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngân sách tổng tháng ${_formatMonth(month)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _HeroInfoRow(
            icon: Icons.call_split_rounded,
            label: 'Đã phân bổ vào $jarCount hũ',
            value: CurrencyFormatter.format(allocatedBudget),
          ),
          const SizedBox(height: 8),
          _HeroInfoRow(
            icon: Icons.savings_rounded,
            label: 'Còn lại trong hũ',
            value: CurrencyFormatter.format(remainingInJars),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String yyyyMM) {
    final parts = yyyyMM.split('-');
    if (parts.length != 2) return yyyyMM;
    return '${parts[1]}/${parts[0]}';
  }
}

class _HeroInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JarCard extends StatelessWidget {
  final SpendingJarModel jar;
  final double spent;
  final double remaining;
  final double progress;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _JarCard({
    required this.jar,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.categoryName,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(jar.colorValue);

    return CommonCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconFromKey(jar.icon), color: color, size: 24),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã dùng ${CurrencyFormatter.format(spent)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                'Còn ${CurrencyFormatter.format(remaining)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Phân bổ ${CurrencyFormatter.format(jar.amount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFromKey(String key) {
    switch (key) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.savings_rounded;
    }
  }
}

class _EmptyJarsCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyJarsCard({required this.onCreate});

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
            'Tạo hũ để phân bổ ngân sách tháng thành từng mục nhỏ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo hũ mới'),
          ),
        ],
      ),
    );
  }
}

class _CreateJarCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateJarCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CommonCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo hũ mới',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Phân bổ từ ngân sách tổng của tháng',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

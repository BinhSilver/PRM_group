import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/spending_jar_provider.dart';
import '../database/database_helper.dart';
import '../widgets/common_card.dart';
import '../utils/app_constants.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String _type = 'expense';
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?.title);
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: widget.transaction?.note);

    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
      _selectedCategoryId = widget.transaction!.categoryId;
    }

    _loadCategoriesByType();
  }

  Future<void> _loadCategoriesByType() async {
    final userId = context.read<UserProvider>().currentUser?.id ?? 1;
    var data = await DatabaseHelper.instance.getCategoriesByType(_type, userId);

    // Nếu chưa có danh mục nào (cho user cũ đã lỡ đăng ký), tự động tạo bộ mặc định
    if (data.isEmpty) {
      await DatabaseHelper.instance.seedDefaultCategories(userId: userId);
      data = await DatabaseHelper.instance.getCategoriesByType(_type, userId);
    }

    if (!mounted) return;

    setState(() {
      _categories = data.map((e) => CategoryModel.fromMap(e)).toList();

      if (_categories.isNotEmpty) {
        // Kiểm tra xem category đã chọn có còn nằm trong danh sách mới không
        final selectedExists = _categories.any(
          (c) => c.id == _selectedCategoryId,
        );
        if (_selectedCategoryId == null || !selectedExists) {
          _selectedCategoryId = _categories.first.id;
        }
      } else {
        _selectedCategoryId = null;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final jarProvider = context.read<SpendingJarProvider>();
    final userId = userProvider.currentUser?.id ?? 1;

    setState(() => _isSaving = true);

    final tx = TransactionModel(
      id: widget.transaction?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      type: _type,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim(),
      date: _selectedDate,
      userId: userId,
    );

    try {
      if (widget.transaction == null) {
        await txProvider.addTransaction(tx);
      } else {
        await txProvider.updateTransaction(tx);
      }

      // Đồng bộ dữ liệu ngân sách sau khi thay đổi giao dịch
      if (mounted) {
        await budgetProvider.loadBudgets(userId);
        await jarProvider.loadJars(userId);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phân loại: Chi tiêu / Thu nhập
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTypeOption('expense', 'Chi tiêu'),
                        const SizedBox(width: 20),
                        _buildTypeOption('income', 'Thu nhập'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tiêu đề
                    _buildInputField(
                      controller: _titleController,
                      label: 'Tiêu đề',
                      icon: Icons.title,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Số tiền
                    _buildInputField(
                      controller: _amountController,
                      label: 'Số tiền',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return 'Số tiền phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Danh mục
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            isExpanded: true,
                            menuMaxHeight:
                                300, // Giới hạn chiều cao menu dropdown
                            decoration: InputDecoration(
                              labelText: 'Danh mục',
                              labelStyle: const TextStyle(fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              filled: false,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (v) =>
                                      setState(() => _selectedCategoryId = v),
                            validator: (v) =>
                                v == null ? 'Vui lòng chọn danh mục' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ngày tháng
                    InkWell(
                      onTap: _isSaving
                          ? null
                          : () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate.isAfter(now)
                                    ? now
                                    : _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: now,
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Divider(height: 1, color: theme.dividerColor),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ghi chú
                    _buildInputField(
                      controller: _noteController,
                      label: 'Ghi chú',
                      icon: Icons.note,
                      maxLines: 2,
                      maxLength: 500,
                      alignLabelWithHint: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút Lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _type == 'expense'
                        ? AppColors.primary
                        : AppColors.income,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'CẬP NHẬT GIAO DỊCH' : 'LƯU GIAO DỊCH',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String value, String label) {
    final isSelected = _type == value;

    return InkWell(
      onTap: _isSaving
          ? null
          : () {
              setState(() {
                _type = value;
                _selectedCategoryId = null;
              });
              _loadCategoriesByType();
            },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: _type,
              activeColor: AppColors.primary,
              onChanged: _isSaving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _type = v;
                        _selectedCategoryId = null;
                      });
                      _loadCategoriesByType();
                    },
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.lightTextSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool alignLabelWithHint = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: alignLabelWithHint
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: alignLabelWithHint ? 12 : 0),
          child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: !_isSaving,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: label,
              counterText: maxLength == 500
                  ? null
                  : "", // Hiện counter cho ghi chú
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

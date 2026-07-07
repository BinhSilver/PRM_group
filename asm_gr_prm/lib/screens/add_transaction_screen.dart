import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/category_model.dart';
import '../services/transaction_service.dart';
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
  final _service = TransactionService();
  
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
    _amountController = TextEditingController(text: widget.transaction?.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: widget.transaction?.note);
    
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _selectedDate = DateTime.parse(widget.transaction!.date);
      _selectedCategoryId = widget.transaction!.categoryId;
    }

    _loadCategoriesByType();
  }

  Future<void> _loadCategoriesByType() async {
    // Giả sử userId = 1
    final data = await DatabaseHelper.instance.getCategoriesByType(_type, 1);
    
    if (!mounted) return;

    setState(() {
      _categories = data.map((e) => CategoryModel.fromMap(e)).toList();
      
      if (_categories.isNotEmpty) {
        // Kiểm tra xem category đã chọn có còn nằm trong danh sách mới không
        final selectedExists = _categories.any((c) => c.id == _selectedCategoryId);
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

    setState(() => _isSaving = true);

    final tx = TransactionModel(
      id: widget.transaction?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      type: _type,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim(),
      date: _selectedDate.toIso8601String(),
      userId: 1, 
    );

    try {
      if (widget.transaction == null) {
        await _service.addTransaction(tx);
      } else {
        await _service.editTransaction(tx);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
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

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Chi tiêu'),
                            value: 'expense',
                            groupValue: _type,
                            onChanged: _isSaving ? null : (v) {
                              if (v == null) return;
                              setState(() {
                                _type = v;
                                // Reset category để load lại theo type mới
                                _selectedCategoryId = null;
                              });
                              _loadCategoriesByType();
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Thu nhập'),
                            value: 'income',
                            groupValue: _type,
                            onChanged: _isSaving ? null : (v) {
                              if (v == null) return;
                              setState(() {
                                _type = v;
                                _selectedCategoryId = null;
                              });
                              _loadCategoriesByType();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isSaving,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        prefixIcon: Icon(Icons.title),
                        counterText: "", // Ẩn counter để gọn UI
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                        if (v.trim().length > 100) return 'Tiêu đề tối đa 100 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      enabled: !_isSaving,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền',
                        prefixIcon: Icon(Icons.attach_money),
                        counterText: "",
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) return 'Số tiền phải lớn hơn 0';
                        if (amount > 1000000000000) return 'Số tiền quá lớn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      )).toList(),
                      onChanged: _isSaving ? null : (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                    ),
                    const SizedBox(height: 16),
                    // ... (phần ListTile ngày tháng giữ nguyên)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _isSaving ? null : () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: now,
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      enabled: !_isSaving,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        if (v != null && v.length > 500) return 'Ghi chú tối đa 500 ký tự';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'CẬP NHẬT GIAO DỊCH' : 'LƯU GIAO DỊCH'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/user_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/common_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _amountController = TextEditingController();
  String _selectedMonth = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  String _formatToDisplay(String yyyyMM) {
    final parts = yyyyMM.split('-');
    if (parts.length != 2) return yyyyMM;
    return '${parts[1]}/${parts[0]}';
  }

  String _formatToStorage(String mmYYYY) {
    final parts = mmYYYY.split('/');
    if (parts.length != 2) return mmYYYY;
    return '${parts[1]}-${parts[0]}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    await context.read<BudgetProvider>().setBudget(user.id, _selectedMonth, amount);
    _amountController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ngân sách')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final budgetProvider = context.watch<BudgetProvider>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentBudget = budgetProvider.budgets.firstWhere(
      (b) => b.month == _selectedMonth,
      orElse: () => BudgetModel(month: _selectedMonth, amount: 0, userId: user.id),
    );

    final spent = budgetProvider.getSpent(_selectedMonth);
    final isOver = budgetProvider.isOverBudget(_selectedMonth);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ngân sách tháng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Month selector + amount
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _formatToDisplay(_selectedMonth),
                    decoration: const InputDecoration(labelText: 'Tháng (MM/YYYY)'),
                    onChanged: (v) {
                      setState(() {
                        _selectedMonth = _formatToStorage(v);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ngân sách (VNĐ)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _saveBudget, child: const Text('Lưu')),
              ],
            ),

            const SizedBox(height: 24),
            CommonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngân sách tháng ${_formatToDisplay(_selectedMonth)}'),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(currentBudget.amount),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: currentBudget.amount > 0 ? (spent / currentBudget.amount).clamp(0.0, 1.0) : 0,
                    backgroundColor: Colors.grey.shade300,
                    color: isOver ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text('Đã chi: ${CurrencyFormatter.format(spent)}'),
                  if (isOver)
                    const Text('⚠️ Vượt ngân sách!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Danh sách ngân sách đã đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: budgetProvider.budgets.length,
                itemBuilder: (context, index) {
                  final b = budgetProvider.budgets[index];
                  final s = budgetProvider.getSpent(b.month);
                  return ListTile(
                     title: Text(_formatToDisplay(b.month)),
                    subtitle: Text('Ngân sách: ${CurrencyFormatter.format(b.amount)} | Chi: ${CurrencyFormatter.format(s)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => budgetProvider.deleteBudget(b.id!, user.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

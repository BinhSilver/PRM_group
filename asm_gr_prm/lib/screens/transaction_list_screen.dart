import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'add_transaction_screen.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/spending_jar_provider.dart';
import '../widgets/section_title.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_item_card.dart';
import '../widgets/time_filter_widget.dart';
import '../utils/app_constants.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.currentUser != null) {
      final userId = userProvider.currentUser!.id;
      await context.read<TransactionProvider>().fetchTransactions(userId);
      if (!mounted) return;
      await context.read<SpendingJarProvider>().loadJars(userId);
    }
  }

  Future<void> _deleteTransaction(int id) async {
    final userProvider = context.read<UserProvider>();
    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final jarProvider = context.read<SpendingJarProvider>();
    if (userProvider.currentUser == null) return;

    try {
      final userId = userProvider.currentUser!.id;
      await txProvider.deleteTransaction(id, userId);

      // Cập nhật lại ngân sách sau khi xóa giao dịch
      await budgetProvider.loadBudgets(userId);
      await jarProvider.loadJars(userId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final isLoading = txProvider.isLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeFilterWidget(
                selectedFilter: txProvider.timeFilterType,
                onFilterChanged: (type) {
                  final userId = context.read<UserProvider>().currentUser?.id;
                  if (userId != null) {
                    txProvider.setFilters(userId: userId, timeType: type);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Tổng thu',
                      amount: currencyFormat.format(txProvider.totalIncome),
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.trending_down_rounded,
                      title: 'Tổng chi',
                      amount: currencyFormat.format(txProvider.totalExpense),
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle(title: 'Lịch sử giao dịch'),
              const SizedBox(height: 12),
              if (isLoading && transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Chưa có giao dịch nào'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return TransactionItemCard(
                      transaction: tx,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTransactionScreen(transaction: tx),
                          ),
                        );
                        // TransactionProvider will handle updates via notifyListeners
                      },
                      onDelete: () async {
                        final id = tx.id;
                        if (id == null) return false;
                        await _deleteTransaction(id);
                        return true;
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

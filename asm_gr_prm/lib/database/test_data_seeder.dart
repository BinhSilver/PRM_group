import '../models/transaction_model.dart';
import 'category_repository.dart';
import 'transaction_repository.dart';

class TestDataSeeder {
  static Future<void> seedIfEmpty(int userId) async {
    final transRepo = TransactionRepository();
    if (await transRepo.countTransactions(userId) > 0) return;

    final catRepo = CategoryRepository();
    final categories = await catRepo.getCategories(userId);

    int? categoryId(String name) {
      for (final c in categories) {
        if (c.name == name) return c.id;
      }
      return null;
    }

    final salaryId = categoryId('Lương');
    final foodId = categoryId('Ăn uống');
    final transportId = categoryId('Di chuyển');
    final shoppingId = categoryId('Mua sắm');
    final entertainmentId = categoryId('Giải trí');
    final bonusId = categoryId('Thưởng');

    final now = DateTime.now();
    final transactions = <TransactionModel>[
      TransactionModel(
        title: 'Lương tháng ${now.month}/${now.year}',
        amount: 18500000,
        type: 'income',
        categoryId: salaryId,
        note: 'Lương chính tháng hiện tại',
        date: DateTime(now.year, now.month, 5),
        userId: userId,
      ),
      TransactionModel(
        title: 'Ăn trưa văn phòng',
        amount: 45000,
        type: 'expense',
        categoryId: foodId,
        date: now.subtract(const Duration(days: 1)),
        userId: userId,
      ),
      TransactionModel(
        title: 'Grab đi làm',
        amount: 32000,
        type: 'expense',
        categoryId: transportId,
        date: now.subtract(const Duration(days: 2)),
        userId: userId,
      ),
      TransactionModel(
        title: 'Mua quần áo',
        amount: 350000,
        type: 'expense',
        categoryId: shoppingId,
        note: 'Sale cuối tuần',
        date: now.subtract(const Duration(days: 5)),
        userId: userId,
      ),
      TransactionModel(
        title: 'Xem phim',
        amount: 120000,
        type: 'expense',
        categoryId: entertainmentId,
        date: now.subtract(const Duration(days: 7)),
        userId: userId,
      ),
      TransactionModel(
        title: 'Thưởng dự án',
        amount: 3000000,
        type: 'income',
        categoryId: bonusId,
        date: DateTime(now.year, now.month, 15),
        userId: userId,
      ),
    ];

    final prevMonth = DateTime(now.year, now.month - 1, 1);
    transactions.addAll([
      TransactionModel(
        title: 'Lương tháng ${prevMonth.month}/${prevMonth.year}',
        amount: 18000000,
        type: 'income',
        categoryId: salaryId,
        date: DateTime(prevMonth.year, prevMonth.month, 5),
        userId: userId,
      ),
      TransactionModel(
        title: 'Tiền điện nước',
        amount: 850000,
        type: 'expense',
        categoryId: foodId,
        note: 'Hóa đơn sinh hoạt',
        date: DateTime(prevMonth.year, prevMonth.month, 20),
        userId: userId,
      ),
      TransactionModel(
        title: 'Siêu thị cuối tháng',
        amount: 620000,
        type: 'expense',
        categoryId: shoppingId,
        date: DateTime(prevMonth.year, prevMonth.month, 28),
        userId: userId,
      ),
    ]);

    final twoMonthsAgo = DateTime(now.year, now.month - 2, 1);
    transactions.addAll([
      TransactionModel(
        title: 'Lương tháng ${twoMonthsAgo.month}/${twoMonthsAgo.year}',
        amount: 18000000,
        type: 'income',
        categoryId: salaryId,
        date: DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 5),
        userId: userId,
      ),
      TransactionModel(
        title: 'Ăn uống cuối tuần',
        amount: 280000,
        type: 'expense',
        categoryId: foodId,
        date: DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 12),
        userId: userId,
      ),
    ]);

    for (final transaction in transactions) {
      await transRepo.insertTransaction(transaction);
    }
  }
}
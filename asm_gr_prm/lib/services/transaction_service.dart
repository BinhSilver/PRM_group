import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Thêm giao dịch mới
  Future<int> addTransaction(TransactionModel transaction) async {
    _validate(transaction);
    return await _dbHelper.insertTransaction(transaction);
  }

  // Lấy danh sách giao dịch của một người dùng
  Future<List<TransactionModel>> getAllTransactions(int userId) async {
    return await _dbHelper.getTransactionsByUser(userId);
  }

  // Lấy chi tiết một giao dịch
  Future<TransactionModel?> getTransaction(int id) async {
    return await _dbHelper.getTransactionById(id);
  }

  // Cập nhật giao dịch
  Future<int> editTransaction(TransactionModel transaction) async {
    if (transaction.id == null || transaction.id! <= 0) {
      throw Exception("ID giao dịch không hợp lệ");
    }
    _validate(transaction);
    return await _dbHelper.updateTransaction(transaction);
  }

  // Xóa giao dịch
  Future<int> removeTransaction(int id) async {
    if (id <= 0) {
      throw Exception("ID giao dịch không hợp lệ");
    }
    return await _dbHelper.deleteTransaction(id);
  }

  // Logic Validate dữ liệu
  void _validate(TransactionModel tx) {
    // 1. Validate Tiêu đề
    final title = tx.title.trim();
    if (title.isEmpty) {
      throw Exception("Tiêu đề không được để trống");
    }
    if (title.length > 100) {
      throw Exception("Tiêu đề không được quá 100 ký tự");
    }

    // 2. Validate Số tiền
    if (tx.amount <= 0) {
      throw Exception("Số tiền phải lớn hơn 0");
    }
    if (tx.amount > 1000000000000) {
      throw Exception("Số tiền quá lớn, vui lòng kiểm tra lại");
    }

    // 3. Validate Loại giao dịch
    if (tx.type != 'income' && tx.type != 'expense') {
      throw Exception("Loại giao dịch phải là 'income' hoặc 'expense'");
    }

    // 4. Validate Danh mục
    if (tx.categoryId == null || tx.categoryId! <= 0) {
      throw Exception("Vui lòng chọn danh mục hợp lệ");
    }

    // 5. Validate Ngày tháng
    // Vì TransactionModel đã dùng DateTime nên tx.date không bao giờ trống ở đây
    // Nếu muốn check range có thể thêm ở đây

    // 6. Validate Ghi chú (nếu có)
    if (tx.note != null && tx.note!.length > 500) {
      throw Exception("Ghi chú không được quá 500 ký tự");
    }

    // 7. Validate User
    if (tx.userId <= 0) {
      throw Exception("ID người dùng không hợp lệ");
    }
  }
}

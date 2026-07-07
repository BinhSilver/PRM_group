import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'vi_VN').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MM/yyyy', 'vi_VN').format(date);
  }
}
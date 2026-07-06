import 'package:flutter/material.dart';

import '../widgets/placeholder_module_card.dart';

class TransactionsPlaceholderScreen extends StatelessWidget {
  const TransactionsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PlaceholderModuleCard(
          icon: Icons.receipt_long_rounded,
          title: 'Quản lý giao dịch',
          description:
              'Danh sách thu chi, thêm giao dịch và lịch sử giao dịch sẽ hiển thị tại đây.',
          note: 'Sẵn sàng kết nối với màn hình giao dịch thật.',
        ),
      ),
    );
  }
}

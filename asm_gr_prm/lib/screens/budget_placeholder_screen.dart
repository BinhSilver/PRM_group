import 'package:flutter/material.dart';

import '../widgets/placeholder_module_card.dart';

class BudgetPlaceholderScreen extends StatelessWidget {
  const BudgetPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PlaceholderModuleCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Quản lý ngân sách',
          description:
              'Thiết lập ngân sách tháng và theo dõi mức chi tiêu sẽ hiển thị tại đây.',
          note: 'Sẵn sàng kết nối với màn hình ngân sách thật.',
        ),
      ),
    );
  }
}

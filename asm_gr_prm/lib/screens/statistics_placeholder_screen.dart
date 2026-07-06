import 'package:flutter/material.dart';

import '../widgets/placeholder_module_card.dart';

class StatisticsPlaceholderScreen extends StatelessWidget {
  const StatisticsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PlaceholderModuleCard(
          icon: Icons.pie_chart_rounded,
          title: 'Thống kê tài chính',
          description:
              'Biểu đồ thu chi, báo cáo tháng và xu hướng tài chính sẽ hiển thị tại đây.',
          note: 'Sẵn sàng kết nối với màn hình thống kê thật.',
        ),
      ),
    );
  }
}

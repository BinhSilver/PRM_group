import 'package:flutter/material.dart';

class ProfileActions {
  static Future<void> showChangePasswordPlaceholder(
    BuildContext context,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: const Text('Tính năng đổi mật khẩu sẽ được tích hợp sau.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

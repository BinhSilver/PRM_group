import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryIcons {
  static dynamic getIcon(String? iconName) {
    switch (iconName) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'car':
        return FontAwesomeIcons.car;
      case 'shopping-bag':
        return FontAwesomeIcons.bagShopping;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'stethoscope':
        return FontAwesomeIcons.stethoscope;
      case 'money-bill-wave':
        return FontAwesomeIcons.moneyBillWave;
      case 'gift':
        return FontAwesomeIcons.gift;
      case 'chart-line':
        return FontAwesomeIcons.chartLine;
      case 'wallet':
        return FontAwesomeIcons.wallet;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  static Color getIconColor(String? iconName) {
    switch (iconName) {
      case 'utensils':
        return Colors.orange;
      case 'car':
        return Colors.blue;
      case 'shopping-bag':
        return Colors.purple;
      case 'gamepad':
        return Colors.pink;
      case 'stethoscope':
        return Colors.red;
      case 'money-bill-wave':
        return Colors.green;
      case 'gift':
        return Colors.amber;
      case 'chart-line':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
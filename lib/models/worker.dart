import 'package:flutter/material.dart';

class Worker {
  int? id;
  String name;
  String phone;
  String address;
  double openingBalance;
  double currentBalance;

  Worker({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.openingBalance,
    required this.currentBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      openingBalance: map['openingBalance'] ?? 0,
      currentBalance: map['currentBalance'] ?? 0,
    );
  }

  // ✅ الحصول على حالة الرصيد
  String get balanceStatus {
    if (currentBalance > 0) return 'رصيد للعامل (دائن)';
    if (currentBalance < 0) return 'رصيد على العامل (مدين)';
    return 'رصيد صفر';
  }

  // ✅ الحصول على لون الرصيد
  Color get balanceColor {
    if (currentBalance > 0) return Colors.green;
    if (currentBalance < 0) return Colors.red;
    return Colors.grey;
  }

  // ✅ الحصول على أيقونة الرصيد
  IconData get balanceIcon {
    if (currentBalance > 0) return Icons.arrow_upward;
    if (currentBalance < 0) return Icons.arrow_downward;
    return Icons.remove;
  }

  // ✅ تنسيق الرصيد
  String get formattedBalance {
    return currentBalance.toStringAsFixed(2);
  }
}
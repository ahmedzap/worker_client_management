import 'package:flutter/material.dart';

class Client {
  int? id;
  String name;
  String phone;
  String address;
  String? taxNumber;
  String? notes;
  double openingBalance;
  double currentBalance;
  bool isSupplier;

  Client({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.taxNumber,
    this.notes,
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.isSupplier = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'taxNumber': taxNumber,
      'notes': notes,
      'openingBalance': openingBalance,
      'currentBalance': currentBalance,
      'isSupplier': isSupplier ? 1 : 0,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      taxNumber: map['taxNumber'],
      notes: map['notes'],
      openingBalance: map['openingBalance'] ?? 0,
      currentBalance: map['currentBalance'] ?? 0,
      isSupplier: map['isSupplier'] == 1,
    );
  }

  // ✅ الحصول على حالة الرصيد
  String get balanceStatus {
    if (currentBalance > 0) return 'رصيد على العميل';
    if (currentBalance < 0) return 'رصيد للعميل';
    return 'رصيد صفر';
  }

  // ✅ الحصول على لون الرصيد
  Color get balanceColor {
    if (currentBalance > 0) return Colors.red;
    if (currentBalance < 0) return Colors.green;
    return Colors.grey;
  }
}
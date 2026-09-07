import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Payment {
  int? id;
  int clientId;
  int? invoiceId;
  double amount;
  DateTime date;
  String type; // 'receive' قبض, 'pay' صرف
  String? notes;
  int? currencyId;
  double exchangeRate;

  Payment({
    this.id,
    required this.clientId,
    this.invoiceId,
    required this.amount,
    required this.date,
    required this.type,
    this.notes,
    this.currencyId,
    this.exchangeRate = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'invoiceId': invoiceId,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type,
      'notes': notes,
      'currencyId': currencyId ?? 1,
      'exchangeRate': exchangeRate,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      clientId: map['clientId'],
      invoiceId: map['invoiceId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      notes: map['notes'],
      currencyId: map['currencyId'],
      exchangeRate: map['exchangeRate'] ?? 1.0,
    );
  }

  // ✅ الحصول على نوع الدفع بالعربية
  String get typeName {
    return type == 'receive' ? 'سند قبض' : 'سند صرف';
  }

  // ✅ الحصول على لون الدفع
  Color get typeColor {
    return type == 'receive' ? Colors.green : Colors.red;
  }

  // ✅ الحصول على أيقونة الدفع
  IconData get typeIcon {
    return type == 'receive' ? Icons.arrow_downward : Icons.arrow_upward;
  }

  // ✅ تأثير الدفع على الرصيد
  double get balanceEffect {
    return type == 'receive' ? -amount : amount;
  }
}
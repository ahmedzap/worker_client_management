import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Invoice {
  int? id;
  int clientId;
  String invoiceNumber;
  DateTime date;
  String type; // 'sale' توريد, 'purchase' شراء
  List<InvoiceItem> items;
  double total;
  double paidAmount;
  double remainingAmount;
  int? currencyId;
  double exchangeRate;

  Invoice({
    this.id,
    required this.clientId,
    required this.invoiceNumber,
    required this.date,
    required this.type,
    this.items = const [],
    this.total = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.currencyId,
    this.exchangeRate = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'invoiceNumber': invoiceNumber,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type,
      'total': total,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'currencyId': currencyId ?? 1,
      'exchangeRate': exchangeRate,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      clientId: map['clientId'],
      invoiceNumber: map['invoiceNumber'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      total: map['total'] ?? 0,
      paidAmount: map['paidAmount'] ?? 0,
      remainingAmount: map['remainingAmount'] ?? 0,
      currencyId: map['currencyId'],
      exchangeRate: map['exchangeRate'] ?? 1.0,
      items: [],
    );
  }

  double calculateTotal() {
    total = items.fold(0.0, (sum, item) => sum + item.total);
    return total;
  }

  double calculateRemaining() {
    remainingAmount = total - paidAmount;
    return remainingAmount;
  }

  // ✅ الحصول على نوع الفاتورة بالعربية
  String get typeName {
    return type == 'sale' ? 'توريد' : 'شراء';
  }

  // ✅ الحصول على لون الفاتورة
  Color get typeColor {
    return type == 'sale' ? Colors.blue : Colors.orange;
  }

  // ✅ الحصول على أيقونة الفاتورة
  IconData get typeIcon {
    return type == 'sale' ? Icons.arrow_upward : Icons.arrow_downward;
  }

  // ✅ تنسيق الإجمالي
  String get formattedTotal => total.toStringAsFixed(2);
  String get formattedPaidAmount => paidAmount.toStringAsFixed(2);
  String get formattedRemaining => remainingAmount.toStringAsFixed(2);
}

// ✅ نموذج صنف الفاتورة
class InvoiceItem {
  int? id;
  int invoiceId;
  int productId;
  String productName;
  double quantity;
  double price;
  double totalAmount; // ✅ تغيير الاسم من total إلى totalAmount لتجنب التعارض

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.productId,
    this.productName = '',
    required this.quantity,
    required this.price,
    this.totalAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': quantity * price, // total في قاعدة البيانات
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: map['quantity'],
      price: map['price'],
      totalAmount: map['total'] ?? (map['quantity'] * map['price']),
    );
  }

  // ✅ getter محسوب بدلاً من متغير
  double get total => quantity * price;

  // ✅ تنسيق السعر والإجمالي
  String get formattedPrice => price.toStringAsFixed(2);
  String get formattedTotal => total.toStringAsFixed(2);
  String get formattedQuantity => quantity.toStringAsFixed(2);
}
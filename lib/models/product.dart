import 'package:flutter/material.dart';

class Product {
  int? id;
  String name;
  double clientPrice;   // سعر البيع للعميل
  double workerPrice;   // سعر الإنتاج للعامل
  String type;          // 'client', 'worker', 'both'

  Product({
    this.id,
    required this.name,
    required this.clientPrice,
    required this.workerPrice,
    this.type = 'both',  // افتراضي: عام
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientPrice': clientPrice,
      'workerPrice': workerPrice,
      'type': type,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      clientPrice: map['clientPrice'],
      workerPrice: map['workerPrice'],
      type: map['type'] ?? 'both',
    );
  }

  // ✅ الحصول على نوع الصنف بالعربية
  String get typeName {
    switch (type) {
      case 'client':
        return 'للعميل فقط';
      case 'worker':
        return 'للعامل فقط';
      default:
        return 'عام';
    }
  }

  // ✅ الحصول على لون نوع الصنف
  Color get typeColor {
    switch (type) {
      case 'client':
        return Colors.blue;
      case 'worker':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // ✅ الحصول على أيقونة نوع الصنف
  IconData get typeIcon {
    switch (type) {
      case 'client':
        return Icons.business;
      case 'worker':
        return Icons.people;
      default:
        return Icons.public;
    }
  }

  // ✅ التحقق من أن الصنف متاح للعميل
  bool get isForClient => type == 'client' || type == 'both';

  // ✅ التحقق من أن الصنف متاح للعامل
  bool get isForWorker => type == 'worker' || type == 'both';
}
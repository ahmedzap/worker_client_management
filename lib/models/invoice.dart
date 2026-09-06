import 'package:intl/intl.dart';

class Invoice {
  int? id;
  int clientId;
  int productId;
  double quantity;
  double price;
  DateTime date;
  String type; // 'sale' or 'purchase'

  Invoice({
    this.id,
    required this.clientId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      clientId: map['clientId'],
      productId: map['productId'],
      quantity: map['quantity'],
      price: map['price'],
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }

  double get total => quantity * price;
}
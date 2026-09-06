import 'package:intl/intl.dart';

class Production {
  int? id;
  int workerId;
  int productId;
  double quantity;
  double price;
  DateTime date;

  Production({
    this.id,
    required this.workerId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
  }

  factory Production.fromMap(Map<String, dynamic> map) {
    return Production(
      id: map['id'],
      workerId: map['workerId'],
      productId: map['productId'],
      quantity: map['quantity'],
      price: map['price'],
      date: DateTime.parse(map['date']),
    );
  }

  double get total => quantity * price;
}
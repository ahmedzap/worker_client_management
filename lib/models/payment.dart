import 'package:intl/intl.dart';

class Payment {
  int? id;
  int clientId;
  double amount;
  DateTime date;
  String type; // 'receive' or 'pay'

  Payment({
    this.id,
    required this.clientId,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      clientId: map['clientId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }
}
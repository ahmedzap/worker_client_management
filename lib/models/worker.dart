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
      phone: map['phone'],
      address: map['address'],
      openingBalance: map['openingBalance'],
      currentBalance: map['currentBalance'],
    );
  }
}
class Product {
  int? id;
  String name;
  double clientPrice;
  double workerPrice;

  Product({
    this.id,
    required this.name,
    required this.clientPrice,
    required this.workerPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientPrice': clientPrice,
      'workerPrice': workerPrice,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      clientPrice: map['clientPrice'],
      workerPrice: map['workerPrice'],
    );
  }
}
class Currency {
  int? id;
  String name;
  String symbol;
  double exchangeRate;
  bool isDefault;

  Currency({
    this.id,
    required this.name,
    required this.symbol,
    required this.exchangeRate,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'exchangeRate': exchangeRate,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      exchangeRate: map['exchangeRate'],
      isDefault: map['isDefault'] == 1,
    );
  }

  // ✅ دالة للحصول على العملة الافتراضية
  static Currency getDefaultCurrency(List<Currency> currencies) {
    return currencies.firstWhere(
          (c) => c.isDefault,
      orElse: () => currencies.isNotEmpty ? currencies.first : Currency(
        name: 'ريال يمني',
        symbol: 'ر.ي',
        exchangeRate: 1.0,
        isDefault: true,
      ),
    );
  }
}
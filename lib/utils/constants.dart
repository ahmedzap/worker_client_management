class AppConstants {
  static const String appName = 'إدارة العمال والعملاء';
  static const String version = '1.0.0';

  // الألوان
  static const int primaryColor = 0xFF2196F3;
  static const int workerColor = 0xFFFF9800;
  static const int clientColor = 0xFF4CAF50;

  // تنسيقات التاريخ
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // أنواع الفواتير
  static const String invoiceSale = 'sale';
  static const String invoicePurchase = 'purchase';

  // أنواع المدفوعات
  static const String paymentReceive = 'receive';
  static const String paymentPay = 'pay';

  // أيام الأسبوع
  static const List<String> weekDays = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
}
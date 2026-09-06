import 'package:sqflite/sqflite.dart';

class DatabaseInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // ✅ محاولة تهيئة قاعدة البيانات
      await getDatabasesPath();
      _initialized = true;
      print('✅ تم تهيئة DatabaseInitializer بنجاح');
    } catch (e) {
      print('❌ فشل تهيئة DatabaseInitializer: $e');
      // ✅ محاولة مرة أخرى بعد تأخير
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        await getDatabasesPath();
        _initialized = true;
        print('✅ تم تهيئة DatabaseInitializer بعد المحاولة الثانية');
      } catch (e2) {
        print('❌ فشل تهيئة DatabaseInitializer نهائياً: $e2');
        rethrow;
      }
    }
  }

  static bool get isInitialized => _initialized;
}
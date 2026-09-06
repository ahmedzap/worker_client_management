import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/splash_screen.dart';

void main() async {
  // ✅ تأكد من تهيئة WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة قاعدة البيانات بشكل صحيح
  try {
    // التحقق من أن databaseFactory مهيأ
    final dbPath = await getDatabasesPath();
    print('✅ مسار قاعدة البيانات: $dbPath');
    print('✅ تم تهيئة قاعدة البيانات بنجاح');
  } catch (e) {
    print('❌ خطأ في تهيئة قاعدة البيانات: $e');
    // إعادة المحاولة
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final dbPath = await getDatabasesPath();
      print('✅ مسار قاعدة البيانات بعد المحاولة الثانية: $dbPath');
    } catch (e2) {
      print('❌ فشل تهيئة قاعدة البيانات: $e2');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة العمال والعملاء',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo',
      //  directionality: TextDirection.rtl,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
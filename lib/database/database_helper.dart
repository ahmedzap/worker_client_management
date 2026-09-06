import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/currency.dart';
import '../models/worker.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/production.dart';
import '../models/expense.dart';
import '../models/invoice.dart';
import '../models/payment.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final String dbPath = await getDatabasesPath();
      final String path = join(dbPath, 'app_database.db');

      print('📁 مسار قاعدة البيانات: $path');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onOpen: _onOpen,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('❌ خطأ في تهيئة قاعدة البيانات: $e');
      try {
        final String path = join(await getDatabasesPath(), 'app_database.db');
        return await openDatabase(
          path,
          version: 2,
          onCreate: _onCreate,
          onOpen: _onOpen,
        );
      } catch (e2) {
        print('❌ فشل تهيئة قاعدة البيانات: $e2');
        rethrow;
      }
    }
  }

  Future<void> _onOpen(Database db) async {
    await _ensureTablesExist(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _ensureTablesExist(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 ترقية قاعدة البيانات من $oldVersion إلى $newVersion');

    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE productions ADD COLUMN currencyId INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE productions ADD COLUMN exchangeRate REAL DEFAULT 1.0');
        await db.execute('ALTER TABLE expenses ADD COLUMN currencyId INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE expenses ADD COLUMN exchangeRate REAL DEFAULT 1.0');
        await db.execute('ALTER TABLE invoices ADD COLUMN currencyId INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE invoices ADD COLUMN exchangeRate REAL DEFAULT 1.0');
        await db.execute('ALTER TABLE payments ADD COLUMN currencyId INTEGER DEFAULT 1');
        await db.execute('ALTER TABLE payments ADD COLUMN exchangeRate REAL DEFAULT 1.0');
        print('✅ تم تحديث الجداول بإضافة العملة');
      } catch (e) {
        print('⚠️ بعض الأعمدة موجودة بالفعل: $e');
      }
    }

    await _ensureTablesExist(db);
  }

  Future<void> _ensureTablesExist(Database db) async {
    try {
      // ✅ جدول العملات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS currencies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          symbol TEXT NOT NULL,
          exchangeRate REAL NOT NULL,
          isDefault INTEGER DEFAULT 0
        )
      ''');

      // ✅ جدول العمال
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          openingBalance REAL DEFAULT 0,
          currentBalance REAL DEFAULT 0
        )
      ''');

      // ✅ جدول العملاء
      await db.execute('''
        CREATE TABLE IF NOT EXISTS clients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          openingBalance REAL DEFAULT 0,
          currentBalance REAL DEFAULT 0
        )
      ''');

      // ✅ جدول المنتجات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          clientPrice REAL NOT NULL,
          workerPrice REAL NOT NULL
        )
      ''');

      // ✅ جدول الإنتاج
      await db.execute('''
        CREATE TABLE IF NOT EXISTS productions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          date TEXT NOT NULL,
          currencyId INTEGER DEFAULT 1,
          exchangeRate REAL DEFAULT 1.0,
          FOREIGN KEY (workerId) REFERENCES workers(id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');

      // ✅ جدول المصروفات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          currencyId INTEGER DEFAULT 1,
          exchangeRate REAL DEFAULT 1.0,
          FOREIGN KEY (workerId) REFERENCES workers(id) ON DELETE CASCADE
        )
      ''');

      // ✅ جدول الفواتير
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoices(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          quantity REAL NOT NULL,
          price REAL NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          currencyId INTEGER DEFAULT 1,
          exchangeRate REAL DEFAULT 1.0,
          FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');

      // ✅ جدول المدفوعات
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clientId INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          currencyId INTEGER DEFAULT 1,
          exchangeRate REAL DEFAULT 1.0,
          FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE CASCADE
        )
      ''');

      // ✅ إضافة العملات الافتراضية إذا لم تكن موجودة
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM currencies')
      ) ?? 0;

      if (count == 0) {
        await db.insert('currencies', {
          'name': 'الريال اليمني',
          'symbol': 'ر.ي',
          'exchangeRate': 1.0,
          'isDefault': 1,
        });

        await db.insert('currencies', {
          'name': 'الريال السعودي',
          'symbol': 'ر.س',
          'exchangeRate': 3.75,
          'isDefault': 0,
        });
        print('✅ تم إضافة العملات الافتراضية');
      }

      print('✅ تم التأكد من وجود جميع الجداول');
    } catch (e) {
      print('❌ خطأ في إنشاء الجداول: $e');
      rethrow;
    }
  }

  // ==================== عمليات العملات ====================

  Future<List<Currency>> getCurrencies() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('currencies');
      return List.generate(maps.length, (i) => Currency.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب العملات: $e');
      return [];
    }
  }

  // ✅ دالة الحصول على العملة الافتراضية - تعيد Currency? (nullable)
  Future<Currency?> getDefaultCurrency() async {
    try {
      final currencies = await getCurrencies();
      if (currencies.isEmpty) return null;

      // البحث عن العملة الافتراضية
      for (var currency in currencies) {
        if (currency.isDefault) {
          return currency;
        }
      }

      // إذا لم توجد عملة افتراضية، أرجع أول عملة
      return currencies.first;
    } catch (e) {
      print('❌ خطأ في جلب العملة الافتراضية: $e');
      return null;
    }
  }

  // ✅ دالة الحصول على العملة الافتراضية - تعيد Currency (non-nullable) مع قيمة افتراضية
  Future<Currency> getDefaultCurrencyOrElse() async {
    try {
      final defaultCurrency = await getDefaultCurrency();
      if (defaultCurrency != null) {
        return defaultCurrency;
      }

      // إذا لم توجد عملة، أنشئ عملة افتراضية
      return Currency(
        id: 1,
        name: 'الريال اليمني',
        symbol: 'ر.ي',
        exchangeRate: 1.0,
        isDefault: true,
      );
    } catch (e) {
      print('❌ خطأ في جلب العملة الافتراضية: $e');
      return Currency(
        id: 1,
        name: 'الريال اليمني',
        symbol: 'ر.ي',
        exchangeRate: 1.0,
        isDefault: true,
      );
    }
  }

  // ✅ دالة تغيير العملة الافتراضية
  Future<bool> setDefaultCurrency(int currencyId) async {
    try {
      final db = await database;

      // ✅ التحقق من وجود العملة
      final List<Map<String, dynamic>> existing = await db.query(
        'currencies',
        where: 'id = ?',
        whereArgs: [currencyId],
      );

      if (existing.isEmpty) {
        print('❌ العملة غير موجودة');
        return false;
      }

      // ✅ إزالة الافتراضية من جميع العملات
      await db.update(
        'currencies',
        {'isDefault': 0},
        where: 'isDefault = ?',
        whereArgs: [1],
      );

      // ✅ تعيين العملة الجديدة كافتراضية
      final result = await db.update(
        'currencies',
        {'isDefault': 1},
        where: 'id = ?',
        whereArgs: [currencyId],
      );

      if (result > 0) {
        print('✅ تم تغيير العملة الافتراضية بنجاح');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في تغيير العملة الافتراضية: $e');
      return false;
    }
  }

  // ✅ دالة الحصول على سعر صرف العملة
  Future<double> getExchangeRate(int currencyId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'currencies',
        where: 'id = ?',
        whereArgs: [currencyId],
      );
      if (result.isNotEmpty) {
        return (result.first['exchangeRate'] as num?)?.toDouble() ?? 1.0;
      }
      return 1.0;
    } catch (e) {
      print('❌ خطأ في جلب سعر الصرف: $e');
      return 1.0;
    }
  }

  // ✅ دالة تحويل المبلغ من عملة لأخرى
  Future<double> convertCurrency(
      double amount,
      int fromCurrencyId,
      int toCurrencyId,
      ) async {
    try {
      final fromRate = await getExchangeRate(fromCurrencyId);
      final toRate = await getExchangeRate(toCurrencyId);

      if (fromRate == 0 || toRate == 0) return amount;

      return amount * (toRate / fromRate);
    } catch (e) {
      print('❌ خطأ في تحويل العملة: $e');
      return amount;
    }
  }

  // ✅ دالة تحويل المبلغ للعملة الأساسية
  Future<double> convertToBaseCurrency(int currencyId, double amount) async {
    try {
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final rate = await getExchangeRate(currencyId);
      final baseRate = defaultCurrency.exchangeRate;

      if (rate == 0) return amount;

      return amount * (baseRate / rate);
    } catch (e) {
      print('❌ خطأ في تحويل المبلغ للعملة الأساسية: $e');
      return amount;
    }
  }

  Future<int> insertCurrency(Currency currency) async {
    try {
      final db = await database;
      final result = await db.insert('currencies', currency.toMap());
      print('✅ تم إضافة العملة: ${currency.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة العملة: $e');
      rethrow;
    }
  }

  Future<int> updateCurrency(Currency currency) async {
    try {
      final db = await database;
      final result = await db.update(
        'currencies',
        currency.toMap(),
        where: 'id = ?',
        whereArgs: [currency.id],
      );
      print('✅ تم تحديث العملة: ${currency.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في تحديث العملة: $e');
      rethrow;
    }
  }

  Future<int> deleteCurrency(int id) async {
    try {
      final db = await database;

      // ✅ التحقق من أن العملة ليست افتراضية
      final List<Map<String, dynamic>> currency = await db.query(
        'currencies',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (currency.isNotEmpty && currency.first['isDefault'] == 1) {
        print('❌ لا يمكن حذف العملة الافتراضية');
        throw Exception('لا يمكن حذف العملة الافتراضية');
      }

      final result = await db.delete(
        'currencies',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ تم حذف العملة');
      return result;
    } catch (e) {
      print('❌ خطأ في حذف العملة: $e');
      rethrow;
    }
  }

  // ==================== عمليات العمال ====================

  Future<List<Worker>> getWorkers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('workers');
      return List.generate(maps.length, (i) => Worker.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب العمال: $e');
      return [];
    }
  }

  Future<Worker?> getWorker(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'workers',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Worker.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب العامل: $e');
      return null;
    }
  }

  Future<int> insertWorker(Worker worker) async {
    try {
      final db = await database;
      final result = await db.insert('workers', worker.toMap());
      print('✅ تم إضافة العامل: ${worker.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة العامل: $e');
      rethrow;
    }
  }

  Future<int> updateWorker(Worker worker) async {
    try {
      final db = await database;
      final result = await db.update(
        'workers',
        worker.toMap(),
        where: 'id = ?',
        whereArgs: [worker.id],
      );
      print('✅ تم تحديث العامل: ${worker.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في تحديث العامل: $e');
      rethrow;
    }
  }

  Future<int> deleteWorker(int id) async {
    try {
      final db = await database;
      await db.delete(
        'productions',
        where: 'workerId = ?',
        whereArgs: [id],
      );
      await db.delete(
        'expenses',
        where: 'workerId = ?',
        whereArgs: [id],
      );
      final result = await db.delete(
        'workers',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ تم حذف العامل');
      return result;
    } catch (e) {
      print('❌ خطأ في حذف العامل: $e');
      rethrow;
    }
  }

  // ==================== عمليات العملاء ====================

  Future<List<Client>> getClients() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('clients');
      return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب العملاء: $e');
      return [];
    }
  }

  Future<Client?> getClient(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clients',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Client.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب العميل: $e');
      return null;
    }
  }

  Future<int> insertClient(Client client) async {
    try {
      final db = await database;
      final result = await db.insert('clients', client.toMap());
      print('✅ تم إضافة العميل: ${client.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة العميل: $e');
      rethrow;
    }
  }

  Future<int> updateClient(Client client) async {
    try {
      final db = await database;
      final result = await db.update(
        'clients',
        client.toMap(),
        where: 'id = ?',
        whereArgs: [client.id],
      );
      print('✅ تم تحديث العميل: ${client.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في تحديث العميل: $e');
      rethrow;
    }
  }

  Future<int> deleteClient(int id) async {
    try {
      final db = await database;
      await db.delete(
        'invoices',
        where: 'clientId = ?',
        whereArgs: [id],
      );
      await db.delete(
        'payments',
        where: 'clientId = ?',
        whereArgs: [id],
      );
      final result = await db.delete(
        'clients',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ تم حذف العميل');
      return result;
    } catch (e) {
      print('❌ خطأ في حذف العميل: $e');
      rethrow;
    }
  }

  // ==================== عمليات المنتجات ====================

  Future<List<Product>> getProducts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('products');
      return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب المنتجات: $e');
      return [];
    }
  }

  Future<Product?> getProduct(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Product.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب المنتج: $e');
      return null;
    }
  }

  Future<int> insertProduct(Product product) async {
    try {
      final db = await database;
      final result = await db.insert('products', product.toMap());
      print('✅ تم إضافة المنتج: ${product.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة المنتج: $e');
      rethrow;
    }
  }

  Future<int> updateProduct(Product product) async {
    try {
      final db = await database;
      final result = await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      print('✅ تم تحديث المنتج: ${product.name}');
      return result;
    } catch (e) {
      print('❌ خطأ في تحديث المنتج: $e');
      rethrow;
    }
  }

  Future<int> deleteProduct(int id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ تم حذف المنتج');
      return result;
    } catch (e) {
      print('❌ خطأ في حذف المنتج: $e');
      rethrow;
    }
  }

  // ==================== عمليات الإنتاج ====================

  Future<List<Production>> getProductionsByWorker(int workerId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productions',
        where: 'workerId = ?',
        whereArgs: [workerId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Production.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب الإنتاج: $e');
      return [];
    }
  }

  // ✅ إضافة حركة إنتاج مع العملة
  Future<int> insertProductionWithCurrency(
      Production production,
      int currencyId,
      double exchangeRate,
      ) async {
    try {
      final db = await database;

      final map = production.toMap();
      map['currencyId'] = currencyId;
      map['exchangeRate'] = exchangeRate;

      final result = await db.insert('productions', map);
      await updateWorkerBalance(production.workerId);
      print('✅ تم إضافة حركة إنتاج مع العملة');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة الإنتاج: $e');
      rethrow;
    }
  }

  Future<int> insertProduction(Production production) async {
    try {
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final currencyId = defaultCurrency.id ?? 1;
      final exchangeRate = defaultCurrency.exchangeRate;
      return await insertProductionWithCurrency(production, currencyId, exchangeRate);
    } catch (e) {
      print('❌ خطأ في إضافة الإنتاج: $e');
      rethrow;
    }
  }

  // ==================== عمليات المصروفات ====================

  Future<List<Expense>> getExpensesByWorker(int workerId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'workerId = ?',
        whereArgs: [workerId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب المصروفات: $e');
      return [];
    }
  }

  // ✅ إضافة مصروف مع العملة
  Future<int> insertExpenseWithCurrency(
      Expense expense,
      int currencyId,
      double exchangeRate,
      ) async {
    try {
      final db = await database;

      final map = expense.toMap();
      map['currencyId'] = currencyId;
      map['exchangeRate'] = exchangeRate;

      final result = await db.insert('expenses', map);
      await updateWorkerBalance(expense.workerId);
      print('✅ تم إضافة مصروف مع العملة');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة المصروف: $e');
      rethrow;
    }
  }

  Future<int> insertExpense(Expense expense) async {
    try {
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final currencyId = defaultCurrency.id ?? 1;
      final exchangeRate = defaultCurrency.exchangeRate;
      return await insertExpenseWithCurrency(expense, currencyId, exchangeRate);
    } catch (e) {
      print('❌ خطأ في إضافة المصروف: $e');
      rethrow;
    }
  }

  // ==================== عمليات الفواتير ====================

  Future<List<Invoice>> getInvoicesByClient(int clientId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'invoices',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Invoice.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب الفواتير: $e');
      return [];
    }
  }

  // ✅ إضافة فاتورة مع العملة
  Future<int> insertInvoiceWithCurrency(
      Invoice invoice,
      int currencyId,
      double exchangeRate,
      ) async {
    try {
      final db = await database;

      final map = invoice.toMap();
      map['currencyId'] = currencyId;
      map['exchangeRate'] = exchangeRate;

      final result = await db.insert('invoices', map);
      await updateClientBalance(invoice.clientId);
      print('✅ تم إضافة فاتورة مع العملة');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة الفاتورة: $e');
      rethrow;
    }
  }

  Future<int> insertInvoice(Invoice invoice) async {
    try {
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final currencyId = defaultCurrency.id ?? 1;
      final exchangeRate = defaultCurrency.exchangeRate;
      return await insertInvoiceWithCurrency(invoice, currencyId, exchangeRate);
    } catch (e) {
      print('❌ خطأ في إضافة الفاتورة: $e');
      rethrow;
    }
  }

  // ==================== عمليات المدفوعات ====================

  Future<List<Payment>> getPaymentsByClient(int clientId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'payments',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e) {
      print('❌ خطأ في جلب المدفوعات: $e');
      return [];
    }
  }

  // ✅ إضافة دفعة مع العملة
  Future<int> insertPaymentWithCurrency(
      Payment payment,
      int currencyId,
      double exchangeRate,
      ) async {
    try {
      final db = await database;

      final map = payment.toMap();
      map['currencyId'] = currencyId;
      map['exchangeRate'] = exchangeRate;

      final result = await db.insert('payments', map);
      await updateClientBalance(payment.clientId);
      print('✅ تم إضافة دفعة مع العملة');
      return result;
    } catch (e) {
      print('❌ خطأ في إضافة المدفوعات: $e');
      rethrow;
    }
  }

  Future<int> insertPayment(Payment payment) async {
    try {
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final currencyId = defaultCurrency.id ?? 1;
      final exchangeRate = defaultCurrency.exchangeRate;
      return await insertPaymentWithCurrency(payment, currencyId, exchangeRate);
    } catch (e) {
      print('❌ خطأ في إضافة المدفوعات: $e');
      rethrow;
    }
  }

  // ==================== تحديث الأرصدة ====================

  Future<void> updateWorkerBalance(int workerId) async {
    try {
      final db = await database;
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final baseRate = defaultCurrency.exchangeRate;

      final productions = await db.query(
        'productions',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );

      double totalProduction = 0;
      for (var prod in productions) {
        double quantity = (prod['quantity'] as num?)?.toDouble() ?? 0;
        double price = (prod['price'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (prod['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        double amount = quantity * price;
        totalProduction += amount * (baseRate / exchangeRate);
      }

      final expenses = await db.query(
        'expenses',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );

      double totalExpenses = 0;
      for (var exp in expenses) {
        double amount = (exp['amount'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (exp['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        totalExpenses += amount * (baseRate / exchangeRate);
      }

      double currentBalance = totalProduction - totalExpenses;

      await db.update(
        'workers',
        {'currentBalance': currentBalance},
        where: 'id = ?',
        whereArgs: [workerId],
      );
    } catch (e) {
      print('❌ خطأ في تحديث رصيد العامل: $e');
    }
  }

  Future<void> updateClientBalance(int clientId) async {
    try {
      final db = await database;
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final baseRate = defaultCurrency.exchangeRate;

      final invoices = await db.query(
        'invoices',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );

      double totalInvoices = 0;
      for (var inv in invoices) {
        double quantity = (inv['quantity'] as num?)?.toDouble() ?? 0;
        double price = (inv['price'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (inv['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        double amount = quantity * price;
        totalInvoices += amount * (baseRate / exchangeRate);
      }

      final payments = await db.query(
        'payments',
        where: 'clientId = ?',
        whereArgs: [clientId],
      );

      double totalPayments = 0;
      for (var pm in payments) {
        double amount = (pm['amount'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (pm['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        totalPayments += amount * (baseRate / exchangeRate);
      }

      double currentBalance = totalInvoices - totalPayments;

      await db.update(
        'clients',
        {'currentBalance': currentBalance},
        where: 'id = ?',
        whereArgs: [clientId],
      );
    } catch (e) {
      print('❌ خطأ في تحديث رصيد العميل: $e');
    }
  }

  // ==================== التقارير ====================

  Future<List<Map<String, dynamic>>> getWeeklyReport(int workerId, DateTime startDate) async {
    try {
      final db = await database;
      final endDate = startDate.add(const Duration(days: 6));

      final String startStr = startDate.toIso8601String().split('T')[0];
      final String endStr = endDate.toIso8601String().split('T')[0];

      final List<Map<String, dynamic>> productions = await db.rawQuery('''
        SELECT p.*, pr.name as productName 
        FROM productions p
        JOIN products pr ON p.productId = pr.id
        WHERE p.workerId = ? AND p.date BETWEEN ? AND ?
        ORDER BY p.date
      ''', [workerId, startStr, endStr]);

      final List<Map<String, dynamic>> expenses = await db.rawQuery('''
        SELECT * FROM expenses
        WHERE workerId = ? AND date BETWEEN ? AND ?
        ORDER BY date
      ''', [workerId, startStr, endStr]);

      double totalProduction = 0;
      double totalExpenses = 0;

      final defaultCurrency = await getDefaultCurrencyOrElse();
      final baseRate = defaultCurrency.exchangeRate;

      for (var prod in productions) {
        double quantity = (prod['quantity'] as num?)?.toDouble() ?? 0;
        double price = (prod['price'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (prod['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        double amount = quantity * price;
        totalProduction += amount * (baseRate / exchangeRate);
      }

      for (var exp in expenses) {
        double amount = (exp['amount'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (exp['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        totalExpenses += amount * (baseRate / exchangeRate);
      }

      double net = totalProduction - totalExpenses;

      return [
        {
          'productions': productions,
          'expenses': expenses,
        },
        {
          'totalProduction': totalProduction,
          'totalExpenses': totalExpenses,
          'net': net,
        }
      ];
    } catch (e) {
      print('❌ خطأ في إنشاء التقرير الأسبوعي: $e');
      return [
        {'productions': [], 'expenses': []},
        {'totalProduction': 0, 'totalExpenses': 0, 'net': 0}
      ];
    }
  }

  // ✅ تقرير شهري
  Future<List<Map<String, dynamic>>> getMonthlyReport(int workerId, DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    return await getWeeklyReport(workerId, startDate);
  }

  // ✅ كشف حساب العميل
  Future<Map<String, dynamic>> getClientStatement(int clientId) async {
    try {
      final db = await database;
      final defaultCurrency = await getDefaultCurrencyOrElse();
      final baseRate = defaultCurrency.exchangeRate;

      final invoices = await db.query(
        'invoices',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'date DESC',
      );

      final payments = await db.query(
        'payments',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'date DESC',
      );

      double totalInvoices = 0;
      for (var inv in invoices) {
        double quantity = (inv['quantity'] as num?)?.toDouble() ?? 0;
        double price = (inv['price'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (inv['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        double amount = quantity * price;
        totalInvoices += amount * (baseRate / exchangeRate);
      }

      double totalPayments = 0;
      for (var pm in payments) {
        double amount = (pm['amount'] as num?)?.toDouble() ?? 0;
        double exchangeRate = (pm['exchangeRate'] as num?)?.toDouble() ?? 1.0;
        totalPayments += amount * (baseRate / exchangeRate);
      }

      return {
        'invoices': invoices,
        'payments': payments,
        'totalInvoices': totalInvoices,
        'totalPayments': totalPayments,
        'balance': totalInvoices - totalPayments,
      };
    } catch (e) {
      print('❌ خطأ في إنشاء كشف حساب العميل: $e');
      return {
        'invoices': [],
        'payments': [],
        'totalInvoices': 0,
        'totalPayments': 0,
        'balance': 0,
      };
    }
  }

  // ✅ حذف جميع البيانات
  Future<void> deleteAllData() async {
    try {
      final db = await database;
      await db.delete('productions');
      await db.delete('expenses');
      await db.delete('invoices');
      await db.delete('payments');
      await db.delete('workers');
      await db.delete('clients');
      await db.delete('products');
      await db.delete('currencies');

      // ✅ إعادة إضافة العملات الافتراضية
      await db.insert('currencies', {
        'name': 'الريال اليمني',
        'symbol': 'ر.ي',
        'exchangeRate': 1.0,
        'isDefault': 1,
      });
      await db.insert('currencies', {
        'name': 'الريال السعودي',
        'symbol': 'ر.س',
        'exchangeRate': 3.75,
        'isDefault': 0,
      });

      print('✅ تم حذف جميع البيانات بنجاح');
    } catch (e) {
      print('❌ خطأ في حذف البيانات: $e');
      rethrow;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/worker.dart';
import '../models/production.dart';
import '../models/expense.dart';
import 'add_production.dart';
import 'add_expense.dart';
import 'worker_statement.dart';
import '../utils/pdf_helper.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final Worker worker;

  const WorkerDetailsScreen({super.key, required this.worker});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<Production> productions = [];
  List<Expense> expenses = [];
  final DatabaseHelper db = DatabaseHelper();
  late TabController _tabController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prods = await db.getProductionsByWorker(widget.worker.id!);
      final exps = await db.getExpensesByWorker(widget.worker.id!);
      setState(() {
        productions = prods;
        expenses = exps;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('حدث خطأ أثناء تحميل البيانات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.worker.name,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'عامل',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _printWeeklyReport,
            tooltip: 'طباعة تقرير أسبوعي',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _printMonthlyReport,
            tooltip: 'طباعة تقرير شهري',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الإنتاج'),
            Tab(text: 'المصروفات'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductionsTab(),
                _buildExpensesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== بطاقة الملخص ====================

  Widget _buildSummaryCard() {
    double totalProduction = productions.fold(0, (sum, p) => sum + p.total);
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double net = totalProduction - totalExpenses;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'إجمالي الإنتاج',
              totalProduction,
              Colors.green,
              Icons.production_quantity_limits,
            ),
            _buildSummaryItem(
              'إجمالي المصروفات',
              totalExpenses,
              Colors.red,
              Icons.money_off,
            ),
            _buildSummaryItem(
              'الصافي',
              net,
              net >= 0 ? Colors.blue : Colors.red,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== تبويب الإنتاج ====================

  Widget _buildProductionsTab() {
    if (productions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.production_quantity_limits, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد حركات إنتاج', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: productions.length,
      itemBuilder: (context, index) {
        final prod = productions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.production_quantity_limits, color: Colors.green),
            ),
            title: Text(
              'المنتج رقم ${prod.productId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الكمية: ${prod.quantity} × السعر: ${NumberFormat('#,##0.00').format(prod.price)}',
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(prod.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(prod.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'إنتاج',
                    style: TextStyle(fontSize: 10, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== تبويب المصروفات ====================

  Widget _buildExpensesTab() {
    if (expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد مصروفات', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.money_off, color: Colors.red),
            ),
            title: Text(
              exp.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(exp.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(exp.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'مصروف',
                    style: TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== دوال الإضافة ====================

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'إضافة حركة جديدة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.production_quantity_limits, color: Colors.green),
              title: const Text('إضافة حركة إنتاج'),
              subtitle: const Text('تسجيل إنتاج جديد للعامل'),
              onTap: () {
                Navigator.pop(context);
                _addProduction();
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off, color: Colors.red),
              title: const Text('إضافة مصروف'),
              subtitle: const Text('تسجيل مصروف جديد للعامل'),
              onTap: () {
                Navigator.pop(context);
                _addExpense();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              title: const Text('طباعة تقرير أسبوعي'),
              subtitle: const Text('تقرير من الجمعة للخميس'),
              onTap: () {
                Navigator.pop(context);
                _printWeeklyReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.purple),
              title: const Text('طباعة تقرير شهري'),
              subtitle: const Text('تقرير الشهر الحالي'),
              onTap: () {
                Navigator.pop(context);
                _printMonthlyReport();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: const Text('كشف حساب'),
              subtitle: const Text('عرض كشف الحساب مع الفلترة'),
              onTap: () {
                Navigator.pop(context);
                _showStatement();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addProduction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductionScreen(workerId: widget.worker.id!),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(workerId: widget.worker.id!),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showStatement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerStatementScreen(worker: widget.worker),
      ),
    );
  }

  // ==================== دوال الطباعة ====================

  void _printWeeklyReport() async {
    try {
      final now = DateTime.now();
      int daysToSubtract = now.weekday + 1;
      if (daysToSubtract > 7) daysToSubtract = 7;
      final weekStart = now.subtract(Duration(days: daysToSubtract));

      final report = await db.getWeeklyReport(widget.worker.id!, weekStart);
      await PDFHelper.printWorkerReport(
        widget.worker,
        weekStart,
        report,
      );
    } catch (e) {
      _showError('حدث خطأ أثناء إنشاء التقرير الأسبوعي');
    }
  }

  void _printMonthlyReport() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final report = await db.getWeeklyReport(
        widget.worker.id!,
        monthStart,
      );
      await PDFHelper.printWorkerReport(
        widget.worker,
        monthStart,
        report,
      );
    } catch (e) {
      _showError('حدث خطأ أثناء إنشاء التقرير الشهري');
    }
  }

  // ==================== دوال المساعدة ====================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/worker.dart';
import '../models/production.dart';
import '../models/expense.dart';
import 'add_production.dart';
import 'add_expense.dart';
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
  DatabaseHelper db = DatabaseHelper();
  late TabController _tabController;

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
    try {
      final prods = await db.getProductionsByWorker(widget.worker.id!);
      final exps = await db.getExpensesByWorker(widget.worker.id!);
      setState(() {
        productions = prods;
        expenses = exps;
      });
    } catch (e) {
      _showError('حدث خطأ أثناء تحميل البيانات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker.name),
        elevation: 0,
        backgroundColor: Colors.orange,
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
      body: Column(
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

  Widget _buildSummaryCard() {
    double totalProduction = productions.fold(0, (sum, p) => sum + p.total);
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
    double net = totalProduction - totalExpenses;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'إجمالي الإنتاج',
              totalProduction,
              Colors.green,
            ),
            _buildSummaryItem(
              'إجمالي المصروفات',
              totalExpenses,
              Colors.red,
            ),
            _buildSummaryItem(
              'الصافي',
              net,
              net >= 0 ? Colors.blue : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
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

  Widget _buildProductionsTab() {
    if (productions.isEmpty) {
      return const Center(
        child: Text('لا توجد حركات إنتاج'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: productions.length,
      // ✅ التغيير الرئيسي: استخدم itemBuilder بدلاً من builder
      itemBuilder: (context, index) {
        final prod = productions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('المنتج رقم ${prod.productId}'),
            subtitle: Text(
              'الكمية: ${prod.quantity} × السعر: ${NumberFormat('#,##0.00').format(prod.price)}',
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
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(prod.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('لا توجد مصروفات'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: expenses.length,
      // ✅ التغيير الرئيسي: استخدم itemBuilder بدلاً من builder
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(exp.description),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(exp.date)),
            trailing: Text(
              NumberFormat('#,##0.00').format(exp.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.production_quantity_limits, color: Colors.green),
              title: const Text('إضافة حركة إنتاج'),
              onTap: () {
                Navigator.pop(context);
                _addProduction();
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off, color: Colors.red),
              title: const Text('إضافة مصروف'),
              onTap: () {
                Navigator.pop(context);
                _addExpense();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
              title: const Text('طباعة تقرير أسبوعي'),
              onTap: () {
                Navigator.pop(context);
                _printWeeklyReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.purple),
              title: const Text('طباعة تقرير شهري'),
              onTap: () {
                Navigator.pop(context);
                _printMonthlyReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addProduction() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductionScreen(workerId: widget.worker.id!),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } catch (e) {
      _showError('حدث خطأ أثناء إضافة حركة الإنتاج');
    }
  }

  void _addExpense() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(workerId: widget.worker.id!),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } catch (e) {
      _showError('حدث خطأ أثناء إضافة المصروف');
    }
  }

  void _printWeeklyReport() async {
    try {
      final now = DateTime.now();
      // حساب بداية الأسبوع (الجمعة)
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
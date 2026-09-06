import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import 'add_invoice.dart';
import 'add_payment.dart';
import '../utils/pdf_helper.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<Invoice> invoices = [];
  List<Payment> payments = [];
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
      final invs = await db.getInvoicesByClient(widget.client.id!);
      final pms = await db.getPaymentsByClient(widget.client.id!);
      setState(() {
        invoices = invs;
        payments = pms;
      });
    } catch (e) {
      _showError('حدث خطأ أثناء تحميل البيانات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        elevation: 0,
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الفواتير'),
            Tab(text: 'المدفوعات'),
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
                _buildInvoicesTab(),
                _buildPaymentsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalInvoices = invoices.fold(0, (sum, inv) => sum + inv.total);
    double totalPayments = payments.fold(0, (sum, pm) => sum + pm.amount);
    double balance = widget.client.currentBalance;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'إجمالي الفواتير',
              totalInvoices,
              Colors.blue,
            ),
            _buildSummaryItem(
              'إجمالي المدفوعات',
              totalPayments,
              Colors.green,
            ),
            _buildSummaryItem(
              'الرصيد',
              balance,
              balance >= 0 ? Colors.green : Colors.red,
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

  Widget _buildInvoicesTab() {
    if (invoices.isEmpty) {
      return const Center(
        child: Text('لا توجد فواتير'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: invoices.length,
      // ✅ التغيير الرئيسي: استخدم itemBuilder بدلاً من builder
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('المنتج رقم ${inv.productId}'),
            subtitle: Text(
              '${inv.type == 'sale' ? 'توريد' : 'شراء'} | الكمية: ${inv.quantity} × ${NumberFormat('#,##0.00').format(inv.price)}',
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(inv.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: inv.type == 'sale' ? Colors.blue : Colors.orange,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(inv.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (payments.isEmpty) {
      return const Center(
        child: Text('لا توجد مدفوعات'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: payments.length,
      // ✅ التغيير الرئيسي: استخدم itemBuilder بدلاً من builder
      itemBuilder: (context, index) {
        final pm = payments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(pm.type == 'receive' ? 'سند قبض' : 'سند صرف'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(pm.date)),
            trailing: Text(
              NumberFormat('#,##0.00').format(pm.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pm.type == 'receive' ? Colors.green : Colors.red,
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
              leading: const Icon(Icons.receipt_long, color: Colors.blue),
              title: const Text('إضافة فاتورة توريد'),
              onTap: () {
                Navigator.pop(context);
                _addInvoice('sale');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.orange),
              title: const Text('إضافة فاتورة شراء'),
              onTap: () {
                Navigator.pop(context);
                _addInvoice('purchase');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('إضافة سند قبض'),
              onTap: () {
                Navigator.pop(context);
                _addPayment('receive');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.red),
              title: const Text('إضافة سند صرف'),
              onTap: () {
                Navigator.pop(context);
                _addPayment('pay');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.purple),
              title: const Text('طباعة كشف حساب'),
              onTap: () {
                Navigator.pop(context);
                _printStatement();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addInvoice(String type) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddInvoiceScreen(
            clientId: widget.client.id!,
            type: type,
          ),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } catch (e) {
      _showError('حدث خطأ أثناء إضافة الفاتورة');
    }
  }

  void _addPayment(String type) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPaymentScreen(
            clientId: widget.client.id!,
            type: type,
          ),
        ),
      );
      if (result == true) {
        _loadData();
      }
    } catch (e) {
      _showError('حدث خطأ أثناء إضافة المدفوعات');
    }
  }

  void _printStatement() {
    try {
      PDFHelper.printClientReport(widget.client, invoices, payments);
    } catch (e) {
      _showError('حدث خطأ أثناء طباعة التقرير');
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
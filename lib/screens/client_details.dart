import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import 'add_invoice.dart';
import 'add_payment.dart';
import 'edit_client.dart';
import 'client_statement.dart';
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
      final invs = await db.getInvoicesByClient(widget.client.id!);
      final pms = await db.getPaymentsByClient(widget.client.id!);
      setState(() {
        invoices = invs;
        payments = pms;
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
        title: Text(widget.client.name),
        elevation: 0,
        backgroundColor: Colors.green,
        actions: [
          // ✅ زر تعديل العميل
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editClient,
            tooltip: 'تعديل العميل',
          ),
          // ✅ زر طباعة كشف الحساب
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _printStatement,
            tooltip: 'طباعة كشف حساب',
          ),
        ],
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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

  // ==================== بطاقة الملخص ====================

  Widget _buildSummaryCard() {
    double totalInvoices = 0;
    double totalPaid = 0;

    for (var inv in invoices) {
      if (inv.type == 'sale') {
        totalInvoices += inv.total;
      } else {
        totalInvoices -= inv.total;
      }
    }

    for (var pm in payments) {
      if (pm.type == 'receive') {
        totalPaid += pm.amount;
      } else {
        totalPaid -= pm.amount;
      }
    }

    // ✅ الرصيد النهائي مع الرصيد الافتتاحي
    double balance = widget.client.openingBalance + totalInvoices - totalPaid;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'الرصيد الافتتاحي',
              widget.client.openingBalance,
              Colors.blue,
            ),
            _buildSummaryItem(
              'إجمالي الفواتير',
              totalInvoices.abs(),
              Colors.orange,
              totalInvoices >= 0 ? 'مدين' : 'دائن',
            ),
            _buildSummaryItem(
              'إجمالي المدفوعات',
              totalPaid.abs(),
              Colors.green,
              totalPaid >= 0 ? 'مقبوض' : 'مصروف',
            ),
            _buildSummaryItem(
              'الرصيد النهائي',
              balance.abs(),
              balance >= 0 ? Colors.red : Colors.green,
              balance >= 0 ? 'على العميل' : 'للعميل',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color, [String? status]) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (status != null)
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }

  // ==================== تبويب الفواتير ====================

  Widget _buildInvoicesTab() {
    if (invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد فواتير', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: inv.typeColor.withOpacity(0.2),
              child: Icon(
                inv.typeIcon,
                color: inv.typeColor,
                size: 20,
              ),
            ),
            title: Text(
              'فاتورة رقم ${inv.invoiceNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${inv.typeName} | ${inv.items.length} صنف | ${DateFormat('yyyy-MM-dd').format(inv.date)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(inv.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: inv.typeColor,
                  ),
                ),
                if (inv.remainingAmount > 0)
                  Text(
                    'متبقي: ${NumberFormat('#,##0.00').format(inv.remainingAmount)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الأصناف:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...inv.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.quantity} × ${item.price.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.total.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          NumberFormat('#,##0.00').format(inv.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _deleteInvoice(inv),
                          tooltip: 'حذف الفاتورة',
                        ),
                        const Spacer(),
                        if (inv.remainingAmount > 0)
                          ElevatedButton.icon(
                            onPressed: () => _addPaymentForInvoice(inv),
                            icon: const Icon(Icons.payment, size: 16),
                            label: const Text('تسديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== تبويب المدفوعات ====================

  Widget _buildPaymentsTab() {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد مدفوعات', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final pm = payments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: pm.typeColor.withOpacity(0.2),
              child: Icon(
                pm.typeIcon,
                color: pm.typeColor,
              ),
            ),
            title: Text(
              pm.typeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy-MM-dd').format(pm.date)),
                if (pm.notes != null && pm.notes!.isNotEmpty)
                  Text(
                    pm.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (pm.invoiceId != null)
                  Text(
                    'الفاتورة رقم: ${pm.invoiceId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Text(
              NumberFormat('#,##0.00').format(pm.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: pm.typeColor,
                fontSize: 16,
              ),
            ),
            isThreeLine: true,
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
              leading: const Icon(Icons.receipt_long, color: Colors.blue),
              title: const Text('إضافة فاتورة توريد'),
              subtitle: const Text('فاتورة بيع للعميل'),
              onTap: () {
                Navigator.pop(context);
                _addInvoice('sale');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.orange),
              title: const Text('إضافة فاتورة شراء'),
              subtitle: const Text('فاتورة شراء من العميل'),
              onTap: () {
                Navigator.pop(context);
                _addInvoice('purchase');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('إضافة سند قبض'),
              subtitle: const Text('استلام مبلغ من العميل'),
              onTap: () {
                Navigator.pop(context);
                _addPayment('receive');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.red),
              title: const Text('إضافة سند صرف'),
              subtitle: const Text('دفع مبلغ للعميل'),
              onTap: () {
                Navigator.pop(context);
                _addPayment('pay');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.purple),
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

  // ==================== دوال التنقل ====================

  void _editClient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClientScreen(client: widget.client),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _addInvoice(String type) async {
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
  }

  void _addPayment(String type) async {
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
  }

  void _addPaymentForInvoice(Invoice invoice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPaymentScreen(
          clientId: widget.client.id!,
          type: 'receive',
        ),
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
        builder: (context) => ClientStatementScreen(client: widget.client),
      ),
    );
  }

  // ==================== دوال الحذف ====================

  void _deleteInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الفاتورة رقم ${invoice.invoiceNumber}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await db.deleteInvoice(invoice.id!);
                Navigator.pop(context);
                _loadData();
                _showSuccess('تم حذف الفاتورة بنجاح');
              } catch (e) {
                _showError('خطأ في حذف الفاتورة');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ==================== دوال الطباعة ====================

  void _printStatement() {
    if (invoices.isEmpty && payments.isEmpty) {
      _showError('لا توجد بيانات للطباعة');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طباعة كشف الحساب'),
        content: const Text('هل تريد طباعة كشف الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final statementData = await db.getClientStatementWithOpening(
                  widget.client.id!,
                );
                await PDFHelper.printClientStatement(statementData);
              } catch (e) {
                _showError('خطأ في طباعة كشف الحساب');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('طباعة'),
          ),
        ],
      ),
    );
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
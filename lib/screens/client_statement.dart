import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/client.dart';
import '../utils/pdf_helper.dart';

class ClientStatementScreen extends StatefulWidget {
  final Client client;

  const ClientStatementScreen({super.key, required this.client});

  @override
  State<ClientStatementScreen> createState() => _ClientStatementScreenState();
}

class _ClientStatementScreenState extends State<ClientStatementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper db = DatabaseHelper();
  Map<String, dynamic>? statementData;
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  late TabController _tabController;
  String _selectedFilter = 'الكل'; // الكل, توريد, شراء, قبض, صرف

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
    _startDateController.text = DateFormat('yyyy-MM-dd').format(startDate!);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(endDate!);
    _loadStatement();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatement() async {
    setState(() => isLoading = true);
    try {
      final data = await db.getClientStatementWithOpening(
        widget.client.id!,
        startDate: startDate,
        endDate: endDate,
      );
      setState(() {
        statementData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('خطأ في تحميل كشف الحساب: $e');
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
              'كشف حساب ${widget.client.name}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.client.isSupplier ? 'مورد' : 'عميل',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: statementData != null ? _printStatement : null,
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: statementData != null ? _shareStatement : null,
            tooltip: 'مشاركة',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          if (statementData != null) _buildSummaryCards(),
          _buildFilterChips(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : statementData == null
                ? _buildEmptyState()
                : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[100],
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'الكل'),
                        Tab(text: 'الفواتير'),
                        Tab(text: 'المدفوعات'),
                      ],
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsList('all'),
                        _buildTransactionsList('invoice'),
                        _buildTransactionsList('payment'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== فلتر التاريخ ====================

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _startDateController,
              decoration: const InputDecoration(
                labelText: 'من تاريخ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                filled: true,
                fillColor: Colors.grey,
              ),
              readOnly: true,
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _endDateController,
              decoration: const InputDecoration(
                labelText: 'إلى تاريخ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                filled: true,
                fillColor: Colors.grey,
              ),
              readOnly: true,
              onTap: () => _selectDate(context, false),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _loadStatement,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('عرض'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate! : endDate!,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isStart) {
        setState(() {
          startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      } else {
        setState(() {
          endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    }
  }

  // ==================== بطاقات الملخص ====================

  Widget _buildSummaryCards() {
    final data = statementData!;
    final openingBalance = data['openingBalance'] ?? 0;
    final closingBalance = data['closingBalance'] ?? 0;
    final totalInvoices = data['totalInvoices'] ?? 0;
    final totalPayments = data['totalPayments'] ?? 0;
    final netChange = data['netChange'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'الرصيد الافتتاحي',
              openingBalance,
              Colors.blue,
              Icons.account_balance,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'صافي الحركة',
              netChange,
              netChange >= 0 ? Colors.orange : Colors.red,
              Icons.swap_vert,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'الرصيد النهائي',
              closingBalance,
              closingBalance >= 0 ? Colors.red : Colors.green,
              Icons.account_balance_wallet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat('#,##0.00').format(value),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== فلتر الأصناف ====================

  Widget _buildFilterChips() {
    final filters = ['الكل', 'توريد', 'شراء', 'قبض', 'صرف'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== قائمة الحركات ====================

  Widget _buildTransactionsList(String tabType) {
    final transactions = statementData!['transactions'] as List;

    // ✅ فلترة الحركات حسب التبويب
    List filteredTransactions = transactions.where((item) {
      if (tabType == 'all') return true;
      if (tabType == 'invoice') return item['type'] == 'invoice';
      if (tabType == 'payment') return item['type'] == 'payment';
      return true;
    }).toList();

    // ✅ فلترة حسب النوع المحدد
    if (_selectedFilter != 'الكل') {
      filteredTransactions = filteredTransactions.where((item) {
        if (_selectedFilter == 'توريد') {
          return item['type'] == 'invoice' && item['invoiceType'] == 'sale';
        } else if (_selectedFilter == 'شراء') {
          return item['type'] == 'invoice' && item['invoiceType'] == 'purchase';
        } else if (_selectedFilter == 'قبض') {
          return item['type'] == 'payment' && item['paymentType'] == 'receive';
        } else if (_selectedFilter == 'صرف') {
          return item['type'] == 'payment' && item['paymentType'] == 'pay';
        }
        return true;
      }).toList();
    }

    if (filteredTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد حركات', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final item = filteredTransactions[index];
        return _buildTransactionItem(item);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    final isOpening = item['type'] == 'opening';
    final isInvoice = item['type'] == 'invoice';
    final isPayment = item['type'] == 'payment';

    final date = item['date'] as DateTime;
    final description = item['description'] ?? '';
    final debit = item['debit'] ?? 0;
    final credit = item['credit'] ?? 0;
    final balance = item['balance'] ?? 0;

    Color? backgroundColor;
    IconData? icon;
    Color? iconColor;

    if (isOpening) {
      backgroundColor = Colors.blue.shade50;
      icon = Icons.account_balance;
      iconColor = Colors.blue;
    } else if (isInvoice) {
      if (item['invoiceType'] == 'sale') {
        backgroundColor = Colors.green.shade50;
        icon = Icons.arrow_upward;
        iconColor = Colors.green;
      } else {
        backgroundColor = Colors.orange.shade50;
        icon = Icons.arrow_downward;
        iconColor = Colors.orange;
      }
    } else if (isPayment) {
      if (item['paymentType'] == 'receive') {
        backgroundColor = Colors.green.shade50;
        icon = Icons.arrow_downward;
        iconColor = Colors.green;
      } else {
        backgroundColor = Colors.red.shade50;
        icon = Icons.arrow_upward;
        iconColor = Colors.red;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (backgroundColor ?? Colors.transparent).withOpacity(0.3),
        ),
      ),
      child: isInvoice && item['items'] != null && (item['items'] as List).isNotEmpty
          ? _buildInvoiceExpansionTile(item, icon, iconColor)
          : ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.2),
          child: Icon(icon ?? Icons.receipt, size: 18, color: iconColor ?? Colors.grey),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontWeight: isOpening ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (isInvoice && item['invoiceNumber'] != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'رقم ${item['invoiceNumber']}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (debit > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'مدين: ${NumberFormat('#,##0.00').format(debit)}',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
            if (credit > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'دائن: ${NumberFormat('#,##0.00').format(credit)}',
                  style: const TextStyle(color: Colors.green, fontSize: 11),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              '${balance >= 0 ? 'رصيد' : 'عجز'} ${NumberFormat('#,##0.00').format(balance.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: balance >= 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceExpansionTile(Map<String, dynamic> item, IconData? icon, Color? iconColor) {
    final items = item['items'] as List;
    final invoiceNumber = item['invoiceNumber'] ?? '';
    final date = item['date'] as DateTime;
    final description = item['description'] ?? '';
    final debit = item['debit'] ?? 0;
    final credit = item['credit'] ?? 0;
    final balance = item['balance'] ?? 0;

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.2),
        child: Icon(icon ?? Icons.receipt, size: 18, color: iconColor ?? Colors.grey),
      ),
      title: Text(
        description,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            DateFormat('yyyy-MM-dd').format(date),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'رقم $invoiceNumber',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (debit > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'مدين: ${NumberFormat('#,##0.00').format(debit)}',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
          if (credit > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'دائن: ${NumberFormat('#,##0.00').format(credit)}',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            '${balance >= 0 ? 'رصيد' : 'عجز'} ${NumberFormat('#,##0.00').format(balance.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: balance >= 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل الأصناف',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ رأس الجدول
              Row(
                children: [
                  const Expanded(flex: 3, child: Text('المنتج', style: TextStyle(fontSize: 11, color: Colors.grey))),
                  const Expanded(flex: 1, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                  const Expanded(flex: 1, child: Text('السعر', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey))),
                  const Expanded(flex: 1, child: Text('الإجمالي', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Colors.grey))),
                ],
              ),
              const Divider(),
              ...items.map((itemMap) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(itemMap['productName'] ?? '', style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 1, child: Text('${itemMap['quantity']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 1, child: Text(NumberFormat('#,##0.00').format(itemMap['price']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                    Expanded(flex: 1, child: Text(NumberFormat('#,##0.00').format(itemMap['total']), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              )).toList(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('الإجمالي: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    NumberFormat('#,##0.00').format(debit + credit),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== دوال المساعدة ====================

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد بيانات',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'قم بتحديد فترة زمنية ثم اضغط عرض',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _printStatement() {
    if (statementData != null) {
      PDFHelper.printClientStatement(statementData!);
    }
  }

  void _shareStatement() {
    // TODO: تنفيذ مشاركة كشف الحساب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تجهيز الملف للمشاركة...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
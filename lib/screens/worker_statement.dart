import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/worker.dart';
import '../utils/pdf_helper.dart';

class WorkerStatementScreen extends StatefulWidget {
  final Worker worker;

  const WorkerStatementScreen({super.key, required this.worker});

  @override
  State<WorkerStatementScreen> createState() => _WorkerStatementScreenState();
}

class _WorkerStatementScreenState extends State<WorkerStatementScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper db = DatabaseHelper();
  Map<String, dynamic>? statementData;
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  late TabController _tabController;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    int daysToSubtract = now.weekday + 1;
    if (daysToSubtract > 7) daysToSubtract = 7;
    startDate = now.subtract(Duration(days: daysToSubtract));
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
      final data = await db.getWorkerStatementWithOpening(
        widget.worker.id!,
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
              'كشف حساب ${widget.worker.name}',
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
            onPressed: statementData != null ? _printStatement : null,
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatement,
            tooltip: 'تحديث',
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
                        Tab(text: 'الإنتاج'),
                        Tab(text: 'المصروفات'),
                      ],
                      labelColor: Colors.orange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsList('all'),
                        _buildTransactionsList('production'),
                        _buildTransactionsList('expense'),
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
              backgroundColor: Colors.orange,
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
    final netProfit = data['netProfit'] ?? 0;

    // ✅ حل مشكلة Overflow باستخدام Expanded مع padding صغير
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // ✅ بطاقة 1 - الرصيد الافتتاحي
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance, size: 12, color: Colors.blue),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'الرصيد الافتتاحي',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      NumberFormat('#,##0.00').format(openingBalance),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ✅ بطاقة 2 - صافي الربح
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: netProfit >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'صافي الربح',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      NumberFormat('#,##0.00').format(netProfit),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ✅ بطاقة 3 - الرصيد النهائي
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 12,
                          color: closingBalance >= 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'الرصيد النهائي',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      NumberFormat('#,##0.00').format(closingBalance),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: closingBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== فلتر الأصناف ====================

  Widget _buildFilterChips() {
    final filters = ['الكل', 'إنتاج', 'مصروف'];
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
              selectedColor: Colors.orange[100],
              checkmarkColor: Colors.orange,
              labelStyle: TextStyle(
                color: isSelected ? Colors.orange[700] : Colors.grey[700],
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

    List filteredTransactions = transactions.where((item) {
      if (tabType == 'all') return true;
      if (tabType == 'production') return item['type'] == 'production';
      if (tabType == 'expense') return item['type'] == 'expense';
      return true;
    }).toList();

    if (_selectedFilter != 'الكل') {
      filteredTransactions = filteredTransactions.where((item) {
        if (_selectedFilter == 'إنتاج') {
          return item['type'] == 'production';
        } else if (_selectedFilter == 'مصروف') {
          return item['type'] == 'expense';
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

  // ✅ حل مشكلة Overflow في الحركات
  Widget _buildTransactionItem(Map<String, dynamic> item) {
    final isOpening = item['type'] == 'opening';
    final isProduction = item['type'] == 'production';
    final isExpense = item['type'] == 'expense';

    final date = item['date'] as DateTime;
    final description = item['description'] ?? '';
    final debit = (item['debit'] ?? 0).toDouble();
    final credit = (item['credit'] ?? 0).toDouble();
    final balance = (item['balance'] ?? 0).toDouble();

    Color? backgroundColor;
    IconData? icon;
    Color? iconColor;

    if (isOpening) {
      backgroundColor = Colors.blue.shade50;
      icon = Icons.account_balance;
      iconColor = Colors.blue;
    } else if (isProduction) {
      backgroundColor = Colors.green.shade50;
      icon = Icons.production_quantity_limits;
      iconColor = Colors.green;
    } else if (isExpense) {
      backgroundColor = Colors.red.shade50;
      icon = Icons.money_off;
      iconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (backgroundColor ?? Colors.transparent).withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: (iconColor ?? Colors.grey).withOpacity(0.15),
          child: Icon(icon ?? Icons.receipt, size: 16, color: iconColor ?? Colors.grey),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontWeight: isOpening ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: Colors.grey[800],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
        ),
        // ✅ subtitle بدون Row - استخدام Wrap فقط
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            // ✅ التاريخ - بدون Row زائدة
            Icon(Icons.calendar_today, size: 10, color: Colors.grey[500]),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            // ✅ معلومات المنتج (إذا كان إنتاج)
            if (isProduction && item['productName'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item['productName'] ?? '',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item['quantity']} × ${NumberFormat('#,##0.00').format(item['price'])}',
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (debit > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${NumberFormat('#,##0.00').format(debit)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              if (credit > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${NumberFormat('#,##0.00').format(credit)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              Text(
                'الرصيد: ${NumberFormat('#,##0.00').format(balance)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: balance >= 0 ? Colors.green : Colors.red,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
        isThreeLine: true,
        dense: true,
        minVerticalPadding: 2,
      ),
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
      PDFHelper.printWorkerStatement(statementData!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
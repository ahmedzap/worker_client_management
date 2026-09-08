import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../models/currency.dart';
import '../widgets/currency_dropdown.dart';

class AddInvoiceScreen extends StatefulWidget {
  final int clientId;
  final String type;

  const AddInvoiceScreen({
    super.key,
    required this.clientId,
    required this.type,
  });

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _dateController = TextEditingController();

  List<InvoiceItem> items = [];
  List<Product> products = [];
  List<Currency> currencies = [];

  int? _selectedCurrencyId;
  double _exchangeRate = 1.0;
  final DatabaseHelper db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = _selectedDate.toLocal().toString().split(' ')[0];
    _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prods = await db.getProducts();
      final curr = await db.getCurrencies();

      // ✅ فلترة المنتجات المتاحة للعميل فقط
      final clientProducts = prods.where((p) => p.isForClient).toList();

      // ✅ الحصول على العملة الافتراضية بشكل آمن
      Currency? defaultCurrency;
      if (curr.isNotEmpty) {
        try {
          defaultCurrency = curr.firstWhere(
                (c) => c.isDefault,
            orElse: () => curr.first,
          );
        } catch (e) {
          defaultCurrency = curr.first;
        }
      }

      setState(() {
        products = clientProducts;
        currencies = curr;
        _selectedCurrencyId = defaultCurrency?.id;
        _exchangeRate = defaultCurrency?.exchangeRate ?? 1.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('خطأ في تحميل البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'sale' ? 'إضافة فاتورة توريد' : 'إضافة فاتورة شراء',
        ),
        elevation: 0,
        backgroundColor: widget.type == 'sale' ? Colors.blue : Colors.orange,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() {
                  items.clear();
                });
              },
              tooltip: 'حذف جميع الأصناف',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderFields(),
                    const SizedBox(height: 16),
                    if (products.isEmpty)
                      _buildEmptyProductsMessage(),
                    if (products.isNotEmpty) ...[
                      _buildItemsList(),
                      const SizedBox(height: 16),
                      _buildAddItemButton(),
                      const SizedBox(height: 16),
                      _buildSummary(),
                      const SizedBox(height: 16),
                      _buildCurrencyDropdown(),
                    ],
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ==================== بناء واجهة المستخدم ====================

  Widget _buildEmptyProductsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لا توجد منتجات متاحة للعميل. أضف منتجات في الإعدادات',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الفاتورة';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'التاريخ',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'الأصناف',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} صنف',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              _buildEmptyItemsMessage(),
            if (items.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildItemRow(index, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'أضف أصناف للفاتورة',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, InvoiceItem item) {
    return Dismissible(
      key: Key(item.productId.toString() + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          items.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصنف'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        children: [
          // ✅ اسم المنتج والكمية
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${item.quantity} × ${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // ✅ الإجمالي
          Expanded(
            flex: 1,
            child: Text(
              item.total.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 15,
              ),
            ),
          ),
          // ✅ زر الحذف
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                });
              },
              tooltip: 'حذف',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: products.isEmpty ? null : _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: Text(products.isEmpty ? 'لا توجد منتجات للعميل' : 'إضافة صنف'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = items.fold(0.0, (sum, item) => sum + item.total);

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'إجمالي الفاتورة:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              total.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    if (currencies.isEmpty) return const SizedBox();

    return CurrencyDropdown(
      selectedCurrencyId: _selectedCurrencyId,
      onChanged: (currencyId) {
        setState(() {
          _selectedCurrencyId = currencyId;
          final currency = currencies.firstWhere((c) => c.id == currencyId);
          _exchangeRate = currency.exchangeRate;
        });
      },
      label: 'عملة الفاتورة',
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: items.isEmpty ? null : _saveInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.type == 'sale' ? Colors.blue : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: Text(
            items.isEmpty ? 'أضف أصناف أولاً' : 'حفظ الفاتورة',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  // ==================== دوال التفاعل ====================

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _showAddItemDialog() {
    int? selectedProductId;
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('إضافة صنف', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'المنتج',
                    prefixIcon: Icon(Icons.production_quantity_limits),
                    border: OutlineInputBorder(),
                  ),
                  items: products.map((product) {
                    return DropdownMenuItem<int>(
                      value: product.id,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: product.typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.typeName,
                              style: TextStyle(
                                color: product.typeColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedProductId = value;
                    if (value != null) {
                      final product = products.firstWhere((p) => p.id == value);
                      final price = widget.type == 'sale'
                          ? product.clientPrice
                          : product.workerPrice;
                      priceController.text = price.toString();
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'اختر منتج';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'أدخل الكمية';
                    final numValue = double.tryParse(value);
                    if (numValue == null) return 'أدخل رقم صحيح';
                    if (numValue <= 0) return 'الكمية يجب أن تكون أكبر من صفر';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'أدخل السعر';
                    final numValue = double.tryParse(value);
                    if (numValue == null) return 'أدخل رقم صحيح';
                    if (numValue <= 0) return 'السعر يجب أن يكون أكبر من صفر';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (selectedProductId != null &&
                    quantityController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  final product = products.firstWhere(
                        (p) => p.id == selectedProductId,
                  );
                  final item = InvoiceItem(
                    invoiceId: 0,
                    productId: selectedProductId!,
                    productName: product.name,
                    quantity: double.parse(quantityController.text),
                    price: double.parse(priceController.text),
                  );
                  setState(() {
                    items.add(item);
                  });
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      if (items.isEmpty) {
        _showError('يجب إضافة على الأقل صنف واحد');
        return;
      }

      // ✅ التحقق من عدم تكرار الأصناف
      final productIds = items.map((e) => e.productId).toList();
      if (productIds.length != productIds.toSet().length) {
        _showError('⚠️ يوجد أصناف مكررة في الفاتورة');
        return;
      }

      try {
        final invoice = Invoice(
          clientId: widget.clientId,
          invoiceNumber: _invoiceNumberController.text,
          date: _selectedDate,
          type: widget.type,
          items: items,
          currencyId: _selectedCurrencyId,
          exchangeRate: _exchangeRate,
        );

        invoice.calculateTotal();

        await db.insertInvoiceWithItems(invoice);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ تم حفظ الفاتورة رقم ${invoice.invoiceNumber} بنجاح',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // ✅ إعادة تعيين الحقول
          setState(() {
            items.clear();
            _invoiceNumberController.text = 'INV-${DateTime.now().millisecondsSinceEpoch}';
          });

          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('خطأ في حفظ الفاتورة: $e');
      }
    }
  }

  // ==================== دوال المساعدة ====================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
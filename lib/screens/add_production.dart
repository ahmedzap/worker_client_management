import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/production.dart';
import '../models/product.dart';
import '../models/currency.dart';
import '../widgets/currency_dropdown.dart';

class AddProductionScreen extends StatefulWidget {
  final int workerId;

  const AddProductionScreen({super.key, required this.workerId});

  @override
  State<AddProductionScreen> createState() => _AddProductionScreenState();
}

class _AddProductionScreenState extends State<AddProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  int? _selectedProductId;
  int? _selectedCurrencyId;
  double _exchangeRate = 1.0;
  List<Product> products = [];
  List<Currency> currencies = [];
  final DatabaseHelper db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prods = await db.getProducts();
      final curr = await db.getCurrencies();

      // ✅ فلترة المنتجات المتاحة للعامل فقط
      final workerProducts = prods.where((p) => p.isForWorker).toList();

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
        products = workerProducts;
        currencies = curr;
        _selectedCurrencyId = defaultCurrency?.id;
        _exchangeRate = defaultCurrency?.exchangeRate ?? 1.0;
        if (products.isNotEmpty) {
          _selectedProductId = products[0].id;
          _priceController.text = products[0].workerPrice.toString();
        }
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
        title: const Text('إضافة حركة إنتاج'),
        elevation: 0,
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (products.isEmpty)
                  _buildEmptyProductsMessage(),
                if (products.isNotEmpty) ...[
                  _buildProductDropdown(),
                  const SizedBox(height: 16),
                  _buildQuantityField(),
                  const SizedBox(height: 16),
                  _buildPriceField(),
                  const SizedBox(height: 16),
                  _buildCurrencyDropdown(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  _buildExchangeRateInfo(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== دوال بناء واجهة المستخدم ====================

  Widget _buildEmptyProductsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'لا توجد منتجات متاحة للعامل. أضف منتجات في الإعدادات',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedProductId,
      decoration: const InputDecoration(
        labelText: 'المنتج',
        prefixIcon: Icon(Icons.production_quantity_limits),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: products.map((product) {
        return DropdownMenuItem<int>(
          value: product.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              Flexible(
                child: Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProductId = value;
          final product = products.firstWhere((p) => p.id == value);
          _priceController.text = product.workerPrice.toString();
        });
      },
      validator: (value) {
        if (value == null) return 'يرجى اختيار المنتج';
        return null;
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'الكمية',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال الكمية';
        }
        final numValue = double.tryParse(value);
        if (numValue == null) {
          return 'يرجى إدخال رقم صحيح';
        }
        if (numValue <= 0) {
          return 'الكمية يجب أن تكون أكبر من صفر';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'سعر القطعة',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال السعر';
        }
        final numValue = double.tryParse(value);
        if (numValue == null) {
          return 'يرجى إدخال رقم صحيح';
        }
        if (numValue <= 0) {
          return 'السعر يجب أن يكون أكبر من صفر';
        }
        return null;
      },
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
      label: 'عملة الحركة',
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text(
        'التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}',
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: _selectDate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildExchangeRateInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              'سعر الصرف: $_exchangeRate (سيتم تحويل المبلغ للعملة الأساسية)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveProduction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'حفظ الحركة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      });
    }
  }

  void _saveProduction() async {
    if (_formKey.currentState!.validate()) {
      try {
        final production = Production(
          workerId: widget.workerId,
          productId: _selectedProductId!,
          quantity: double.parse(_quantityController.text),
          price: double.parse(_priceController.text),
          date: _selectedDate,
        );

        await db.insertProductionWithCurrency(
          production,
          _selectedCurrencyId!,
          _exchangeRate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حفظ الحركة بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          _showError('خطأ في حفظ الحركة: $e');
        }
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
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
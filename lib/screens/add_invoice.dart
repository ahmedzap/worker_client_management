import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/product.dart';

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
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  int? _selectedProductId;
  List<Product> products = [];
  DatabaseHelper db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prods = await db.getProducts();
    setState(() {
      products = prods;
      if (products.isNotEmpty) {
        _selectedProductId = products[0].id;
      }
    });
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'المنتج',
                    border: OutlineInputBorder(),
                  ),
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product.id,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                      final product = products.firstWhere((p) => p.id == value);
                      _priceController.text = product.clientPrice.toString();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'يرجى اختيار المنتج';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الكمية';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر القطعة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                ListTile(
                  title: Text('التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type == 'sale' ? Colors.blue : Colors.orange,
                    ),
                    child: const Text(
                      'حفظ الفاتورة',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  void _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final invoice = Invoice(
        clientId: widget.clientId,
        productId: _selectedProductId!,
        quantity: double.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        date: _selectedDate,
        type: widget.type,
      );

      await db.insertInvoice(invoice);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/currency.dart';
import '../widgets/currency_dropdown.dart';

class AddPaymentScreen extends StatefulWidget {
  final int clientId;
  final String type;

  const AddPaymentScreen({
    super.key,
    required this.clientId,
    required this.type,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  int? _selectedCurrencyId;
  double _exchangeRate = 1.0;
  List<Currency> currencies = [];
  final DatabaseHelper db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = _selectedDate.toLocal().toString().split(' ')[0];
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final curr = await db.getCurrencies();

      // ✅ إصلاح الخطأ: الحصول على العملة الافتراضية بشكل صحيح
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
        currencies = curr;
        _selectedCurrencyId = defaultCurrency?.id;
        _exchangeRate = defaultCurrency?.exchangeRate ?? 1.0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ خطأ في تحميل البيانات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'receive' ? 'إضافة سند قبض' : 'إضافة سند صرف',
        ),
        elevation: 0,
        backgroundColor: widget.type == 'receive' ? Colors.green : Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ✅ حقل المبلغ
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المبلغ';
                    }
                    final numValue = double.tryParse(value);
                    if (numValue == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    if (numValue <= 0) {
                      return 'المبلغ يجب أن يكون أكبر من صفر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // ✅ اختيار العملة
                CurrencyDropdown(
                  selectedCurrencyId: _selectedCurrencyId,
                  onChanged: (currencyId) {
                    setState(() {
                      _selectedCurrencyId = currencyId;
                      final currency = currencies.firstWhere(
                            (c) => c.id == currencyId,
                      );
                      _exchangeRate = currency.exchangeRate;
                    });
                  },
                  label: 'عملة الدفع',
                ),
                const SizedBox(height: 15),

                // ✅ حقل الملاحظات
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),

                // ✅ حقل التاريخ
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey,
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 30),

                // ✅ معلومات إضافية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.type == 'receive'
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.type == 'receive'
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.type == 'receive'
                            ? Icons.info_outline
                            : Icons.warning_amber,
                        color: widget.type == 'receive'
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.type == 'receive'
                              ? '✅ سند القبض يقلل من رصيد العميل'
                              : '⚠️ سند الصرف يزيد من رصيد العميل',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.type == 'receive'
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ✅ زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type == 'receive'
                          ? Colors.green
                          : Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.type == 'receive'
                          ? 'حفظ سند القبض'
                          : 'حفظ سند الصرف',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _savePayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final payment = Payment(
          clientId: widget.clientId,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          type: widget.type,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          currencyId: _selectedCurrencyId,
          exchangeRate: _exchangeRate,
        );

        await db.insertPaymentWithCurrency(
          payment,
          _selectedCurrencyId!,
          _exchangeRate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.type == 'receive'
                    ? '✅ تم حفظ سند القبض بنجاح'
                    : '✅ تم حفظ سند الصرف بنجاح',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // ✅ إعادة تعيين الحقول
          setState(() {
            _amountController.clear();
            _notesController.clear();
            _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
            _selectedDate = DateTime.now();
          });

          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ خطأ في حفظ الدفعة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
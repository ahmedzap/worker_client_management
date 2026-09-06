import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';

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
  DatabaseHelper db = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();

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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال المبلغ';
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
                    onPressed: _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type == 'receive' ? Colors.green : Colors.red,
                    ),
                    child: Text(
                      widget.type == 'receive' ? 'حفظ سند القبض' : 'حفظ سند الصرف',
                      style: const TextStyle(fontSize: 18),
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

  void _savePayment() async {
    if (_formKey.currentState!.validate()) {
      final payment = Payment(
        clientId: widget.clientId,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: widget.type,
      );

      await db.insertPayment(payment);
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
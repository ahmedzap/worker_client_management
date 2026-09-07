import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../database/database_helper.dart';

class CurrencyDropdown extends StatefulWidget {
  final int? selectedCurrencyId;
  final Function(int) onChanged;
  final String label;
  final bool isRequired;

  const CurrencyDropdown({
    super.key,
    this.selectedCurrencyId,
    required this.onChanged,
    this.label = 'العملة',
    this.isRequired = true,
  });

  @override
  State<CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<CurrencyDropdown> {
  List<Currency> currencies = [];
  bool isLoading = true;
  int? selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = widget.selectedCurrencyId;
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() => isLoading = true);
    try {
      final db = DatabaseHelper();
      final list = await db.getCurrencies();
      setState(() {
        currencies = list;
        isLoading = false;
        if (selectedId == null && currencies.isNotEmpty) {
          final defaultCurrency = currencies.firstWhere(
                (c) => c.isDefault,
            orElse: () => currencies.first,
          );
          selectedId = defaultCurrency.id;
          widget.onChanged(selectedId!);
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (currencies.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '❌ لا توجد عملات. أضف عملة في الإعدادات',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.currency_exchange, size: 18),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
      items: currencies.map((currency) {
        return DropdownMenuItem<int>(
          value: currency.id,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: currency.isDefault ? Colors.green : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    color: currency.isDefault ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  currency.name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (currency.isDefault) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: Colors.amber),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => selectedId = value);
          widget.onChanged(value);
        }
      },
      validator: (value) {
        if (widget.isRequired && value == null) {
          return 'يرجى اختيار العملة';
        }
        return null;
      },
    );
  }
}
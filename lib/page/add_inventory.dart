import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../inventory_api.dart';

/// Page to add a new inventory item.
class AddInventoryPage extends StatefulWidget {
  /// Pre-filled SKU (barcode) passed from scanner.
  final String sku;
  const AddInventoryPage({Key? key, required this.sku}) : super(key: key);

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reorderController = TextEditingController(
    text: '0',
  );

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.sku);
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sku = _skuController.text;
    final name = _nameController.text;
    final qty = int.parse(_qtyController.text);
    final reorderLevel = int.parse(_reorderController.text);

    try {
      final resp = await InventoryApi().addItem(
        sku: sku,
        name: name,
        quantity: qty,
        // include reorder_level in payload
        reorderLevel: reorderLevel,
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // success → show a Snackbar then pop
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully')),
        );
        Navigator.pop(context, true);
      } else {
        // server‐side validation error, etc.
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to add item: ${resp.statusCode}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } on DioException catch (e) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Network Error'),
              content: Text(e.message ?? 'Unknown network error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Inventory Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
                readOnly: true,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter quantity';
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              TextFormField(
                controller: _reorderController,
                decoration: const InputDecoration(labelText: 'Reorder Level'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter reorder level';
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

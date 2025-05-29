import 'package:flutter/material.dart';
import '../inventory_api.dart';

class InventoryItem {
  final String sku;
  final String name;
  final int quantity;
  InventoryItem({
    required this.sku,
    required this.name,
    required this.quantity,
  });
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity:
          json['quantity'] is int
              ? json['quantity'] as int
              : int.tryParse(json['quantity'].toString()) ?? 0,
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late Future<List<InventoryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  Future<List<InventoryItem>> _fetchItems() async {
    final resp = await InventoryApi().getAllItems();
    if (resp.statusCode == 200) {
      final List<dynamic> data = resp.data as List<dynamic>;
      return data
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load inventory (${resp.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: FutureBuilder<List<InventoryItem>>(
        future: _itemsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No items in inventory.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.name),
                subtitle: Text('SKU: ${item.sku}  •  Qty: ${item.quantity}'),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../inventory_api.dart';
import 'inventory_page.dart' show InventoryItem;

class LowStockPage extends StatefulWidget {
  const LowStockPage({Key? key}) : super(key: key);

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  late Future<List<InventoryItem>> _lowStockFuture;

  @override
  void initState() {
    super.initState();
    _lowStockFuture = _fetchLowStockItems();
  }

  Future<List<InventoryItem>> _fetchLowStockItems() async {
    final resp = await InventoryApi().getLowStockItems();
    if (resp.statusCode == 200) {
      final List<dynamic> data = resp.data as List<dynamic>;
      return data
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch low-stock items (${resp.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock Items')),
      body: FutureBuilder<List<InventoryItem>>(
        future: _lowStockFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('All items are sufficiently stocked.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.warning, color: Colors.red),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Qty: ${item.quantity}  •  Reorder: ${item.reorderLevel}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

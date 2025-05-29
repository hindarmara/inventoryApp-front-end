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
  late List<InventoryItem> _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final resp = await InventoryApi().getAllItems();
    if (resp.statusCode == 200) {
      final data = resp.data as List<dynamic>;
      _items =
          data
              .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
              .toList();
    } else {
      _items = [];
    }
    setState(() => _loading = false);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No items in inventory.'));
    }
    // wrap in SafeArea (or add top padding) to avoid overflow
    return SafeArea(
      top: true,
      bottom: false,
      child: ReorderableListView.builder(
        onReorder: _onReorder,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            key: ValueKey(item.sku),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.inventory_2,
                size: 28,
                color: Colors.grey.shade700,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Qty: ${item.quantity}'),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

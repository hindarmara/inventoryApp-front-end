import 'package:flutter/material.dart';
import '../inventory_api.dart';

class InventoryItem {
  final String sku;
  final String name;
  final int quantity;
  final int reorderLevel;

  InventoryItem({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.reorderLevel,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity:
          json['quantity'] is int
              ? json['quantity'] as int
              : int.tryParse(json['quantity'].toString()) ?? 0,
      reorderLevel:
          json['reorder_level'] is int
              ? json['reorder_level'] as int
              : int.tryParse(json['reorder_level'].toString()) ?? 0,
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
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
    return SafeArea(
      child: ReorderableListView.builder(
        onReorder: _onReorder,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Dismissible(
            key: ValueKey(item.sku),
            direction: DismissDirection.horizontal,
            background: Container(
              alignment: Alignment.centerLeft,
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              // DELETE
              if (direction == DismissDirection.endToStart) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Delete Item'),
                        content: Text('Remove "${item.name}" from inventory?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
                if (confirmed == true) {
                  final resp = await InventoryApi().deleteItem(item.sku);
                  if (resp.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} deleted')),
                    );
                    return true;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Delete failed (${resp.statusCode})'),
                      ),
                    );
                  }
                }
                return false;
              }

              // UPDATE
              if (direction == DismissDirection.startToEnd) {
                final result = await showDialog<InventoryItem>(
                  context: context,
                  builder: (_) {
                    final nameCtrl = TextEditingController(text: item.name);
                    final qtyCtrl = TextEditingController(
                      text: item.quantity.toString(),
                    );
                    final reorderCtrl = TextEditingController(
                      text: item.reorderLevel.toString(),
                    );
                    return AlertDialog(
                      title: const Text('Update Item'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          TextField(
                            controller: qtyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: reorderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reorder Level',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final updated = InventoryItem(
                              sku: item.sku,
                              name: nameCtrl.text,
                              quantity:
                                  int.tryParse(qtyCtrl.text) ?? item.quantity,
                              reorderLevel:
                                  int.tryParse(reorderCtrl.text) ??
                                  item.reorderLevel,
                            );
                            Navigator.pop(context, updated);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null) {
                  final resp = await InventoryApi().updateItem(
                    skuId: result.sku,
                    name: result.name,
                    quantity: result.quantity,
                    reorderLevel: result.reorderLevel,
                  );
                  if (resp.statusCode == 200) {
                    setState(() => _items[index] = result);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${result.name} updated')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Update failed (${resp.statusCode})'),
                      ),
                    );
                  }
                }
                return false; // do not dismiss
              }
              return false;
            },
            onDismissed: (direction) {
              setState(() => _items.removeAt(index));
            },
            child: ListTile(
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
              subtitle: Text(
                'Qty: ${item.quantity} • Reorder: ${item.reorderLevel}',
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}

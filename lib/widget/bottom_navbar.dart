import 'package:flutter/material.dart';

/// A simple BottomNavigationBar with [onTap] callback.
class BottomNavBar extends StatefulWidget {
  /// Current selected index.
  final int currentIndex;

  /// Called when an item is tapped.
  final ValueChanged<int> onTap;

  const BottomNavBar({Key? key, this.currentIndex = 0, required this.onTap})
    : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.barcode_reader), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
      ],
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }
}

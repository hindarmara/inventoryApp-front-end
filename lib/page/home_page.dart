import 'package:flutter/material.dart';
import '../widget/bottom_navbar.dart';
import '../widget/scanner_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // map each tab to a widget
  final List<Widget> _pages = [
    const ScannerScreen(),
    const Center(child: Text('Search')), // placeholder
    const Center(child: Text('Profile')), // placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}


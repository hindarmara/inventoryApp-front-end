import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widget/bottom_navbar.dart'; // ← import your BottomNavBar

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

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

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScannerActive = false;
  MobileScannerController? scannerController;
  String? scanResult;

  // Step 1: Mock barcode data
  /*
  final Map<String, Map<String, dynamic>> mockInventory = {
    '8809294662039': {'name': 'Korean Rice', 'quantity': 5},
    '060383054458': {'name': 'Orange Juice', 'quantity': 12},
  };

  */

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() {
      isScannerActive = !isScannerActive;
      if (isScannerActive) {
        scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } else {
        scannerController?.dispose();
        scannerController = null;
      }
    });
  }

  // Step 2: Show popup result
  Future<void> _showScanResult(BuildContext context, String code) async {
    final url =
        'https://0de5-2604-3d08-d175-1e00-20ff-5cb4-629c-645e.ngrok-free.app/api/inventory/$code';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['name'];
        final qty = data['quantity'];

        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Item Found'),
                content: Text('Product: $name\nQuantity: $qty\nBarcode: $code'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else if (response.statusCode == 404) {
        final bool? shouldAdd = await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Item Not Found'),
                content: Text('Barcode: $code not found in inventory. Would you like to add it?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                ],
              ),
        );
      } else {
        throw Exception('Unexpected error: ${response.statusCode}');
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to fetch data for barcode: $code\n$e'),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Scan a barcode / QR code'),
          const SizedBox(height: 20),
          if (isScannerActive) ...[
            SizedBox(
              height: 300,
              width: 300,
              child: MobileScanner(
                controller: scannerController!,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String code = barcodes.first.rawValue ?? 'Unknown';
                    if (code != scanResult) {
                      setState(() {
                        scanResult = code;
                      });

                      await scannerController?.stop(); // Pause scanning
                      await _showScanResult(
                        context,
                        code,
                      ); // Wait for dialog to close
                      await scannerController?.start(); // Resume scanning
                    }
                  }
                },
              ),
            ),
            if (scanResult != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Last scanned: $scanResult'),
              ),
            ElevatedButton(
              onPressed: _toggleScanner,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Stop Scanner'),
            ),
          ] else
            ElevatedButton(
              onPressed: _toggleScanner,
              child: const Text('Start Scanner'),
            ),
        ],
      ),
    );
  }
}

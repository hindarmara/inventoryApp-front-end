import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: Scaffold(body: Container(child: ScannerScreen()))));
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
  void initState() {
    super.initState();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  void _toggleScanner() {
    setState(() {
      isScannerActive = !isScannerActive;
      print('[DEBUG] Scanner toggled: $isScannerActive');
    });
  }

  void _handleBarcodeDetection(BarcodeCapture capture) async {
  if (!isScannerActive) {
    print('[DEBUG] Scanning is currently disabled');
    return;
  }

  final barcodes = capture.barcodes;
  if (barcodes.isEmpty) {
    print('[DEBUG] No barcodes detected');
    return;
  }

  final String code = barcodes.first.rawValue ?? 'Unknown';

  if (code != scanResult) {
    print('[DEBUG] Barcode detected: $code');

    setState(() {
      scanResult = code;
      isScannerActive = false;
    });

    await _showScanResult(context, code);


  } else {
    print('[DEBUG] Duplicate barcode ignored: $code');
  }
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
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Item Not Found'),
                content: Text('Barcode: $code not found in inventory.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
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
          SizedBox(
            height: 300,
            width: 300,
            child: MobileScanner(
              controller: scannerController!,
              onDetect:
                  _handleBarcodeDetection,
            ),
          ),
          if (scanResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Last scanned: $scanResult'),
            ),
          ElevatedButton(
            onPressed: _toggleScanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: isScannerActive ? Colors.red : Colors.green,
            ),
            child: Text(isScannerActive ? 'Stop Scanning' : 'Start Scanning'),
          ),
        ],
      ),
    );
  }
}

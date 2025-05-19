import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
 final Map<String, Map<String, dynamic>> mockInventory = {
  '8809294662039': {
    'name': 'Korean Rice',
    'quantity': 5,
  },
  '060383054458': {
    'name': 'Orange Juice',
    'quantity': 12,
  },
};


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
  if (mockInventory.containsKey(code)) {
    final item = mockInventory[code]!;
    final name = item['name'];
    final qty = item['quantity'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
  } else {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Item Not Found'),
        content: Text('Barcode: $code \nnot found in inventory.'),
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
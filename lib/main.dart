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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Scan a barcode / QR code'),
          const SizedBox(height: 20),

          // Display scanner or button based on state
          if (isScannerActive) ...[
            SizedBox(
              height: 300,
              width: 300,
              child: MobileScanner(
                controller: scannerController!,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String code = barcodes.first.rawValue ?? 'Unknown';
                    setState(() {
                      scanResult = code;
                    });
                    print('Scanned: $code');
                  }
                },
              ),
            ),
            if (scanResult != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Scanned: $scanResult'),
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

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool handled = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Pickup QR')),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          if (handled) return;
          final String? value = capture.barcodes.first.rawValue;
          if (value == null || value.isEmpty) {
            return;
          }
          handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}

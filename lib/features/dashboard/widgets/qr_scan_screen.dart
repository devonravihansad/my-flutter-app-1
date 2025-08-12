import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatelessWidget {
  final Function(String) onCodeScanned;

  const QRScanScreen({super.key, required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          final code = barcodeCapture.barcodes.first.rawValue ?? '';
          onCodeScanned(code);
        },
      ),
    );
  }
}

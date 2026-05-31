import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/webrtc_service.dart';
import '../utils/app_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _scanned = false;
  String? _error;
  late MobileScannerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;

    // Capture dependencies BEFORE async gap
    final webrtcService = context.read<WebRtcService>();
    final navigator = Navigator.of(context);

    setState(() => _scanned = true);
    await _ctrl.stop();

    final payload = barcode.rawValue!;

    try {
      await webrtcService.connectFromQr(payload);

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _error = 'Invalid QR code: $e';
      });
      await _ctrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webrtc = context.watch<WebRtcService>();

    return Scaffold(
      backgroundColor: T.bg0,
      body: Stack(children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),
        Positioned.fill(child: CustomPaint(painter: _ScanOverlayPainter())),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [T.bg0, T.bg0.withValues(alpha: 0)],
              ),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: T.bg1.withValues(alpha: 0.85),
                    border: Border.all(color: T.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_ios_new,
                        color: T.grey, size: 12),
                    const SizedBox(width: 4),
                    Text('BACK', style: T.mono(9, color: T.grey)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCAN QR CODE', style: T.orb(15)),
                  Text('Point at the QR code displayed on your PC',
                      style: T.mono(9, color: T.grey)),
                ],
              )),
            ]),
          ),
        ),

        // Centre status
        Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 240),
            if (_scanned && webrtc.isConnecting)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: T.teal)),
                const SizedBox(width: 10),
                Text('Connecting via WebRTC…',
                    style: T.mono(10, color: T.teal)),
              ]),
            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: T.red.withValues(alpha: 0.15),
                  border: Border.all(color: T.red),
                ),
                child: Text(_error!,
                    style: T.mono(10, color: T.red),
                    textAlign: TextAlign.center),
              ),
          ],
        )),
      ]),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Example overlay paint
    canvas.drawPath(
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Paint()
          ..color = const Color(0xBB000000)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

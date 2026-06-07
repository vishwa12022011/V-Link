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
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);
    await _ctrl.stop();

    final payload = barcode.rawValue!;
    try {
      await context.read<WebRtcService>().connectFromQr(payload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
        // Camera feed
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),

        // Dark overlay with scan window cutout
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
                colors: [T.bg0, T.bg0.withOpacity(0)],
              ),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: T.bg1.withOpacity(0.85),
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

        // Centre label
        Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // Scan frame corners drawn by overlay painter
            const SizedBox(height: 240), // height of scan window
            const SizedBox(height: 16),
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
                  color: T.red.withOpacity(0.15),
                  border: Border.all(color: T.red),
                ),
                child: Text(_error!,
                    style: T.mono(10, color: T.red),
                    textAlign: TextAlign.center),
              ),
          ],
        )),

        // Bottom hint
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: T.bg1.withOpacity(0.88),
                border: Border.all(color: T.border),
              ),
              child: Column(children: [
                Text('How to get the QR code',
                    style: T.raj(13, color: T.white)),
                const SizedBox(height: 6),
                Text(
                  '1. Run  pc_server/server.js  on your PC\n'
                  '2. Open  http://localhost:3000  in a browser\n'
                  '3. The QR code will appear — scan it here',
                  style: T.mono(9, color: T.grey),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Scan window overlay ───────────────────────────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const winW = 260.0;
    const winH = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;

    final rect =
        Rect.fromCenter(center: Offset(cx, cy), width: winW, height: winH);

    // Dark overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xBB000000)
          ..style = PaintingStyle.fill);

    // Corner brackets
    const cLen = 24.0;
    const cW = 3.0;
    final cPaint = Paint()
      ..color = const Color(0xFFFF4655)
      ..strokeWidth = cW
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    final dirs = [
      [Offset(cLen, 0), Offset(0, cLen)],
      [Offset(-cLen, 0), Offset(0, cLen)],
      [Offset(cLen, 0), Offset(0, -cLen)],
      [Offset(-cLen, 0), Offset(0, -cLen)],
    ];
    for (int i = 0; i < 4; i++) {
      final o = corners[i];
      canvas.drawLine(o, o + dirs[i][0], cPaint);
      canvas.drawLine(o, o + dirs[i][1], cPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

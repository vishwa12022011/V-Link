import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'main_shell.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override State<BootScreen> createState() => _BootState();
}

class _BootState extends State<BootScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fade;
  double _progress = 0;
  int _visible = 0;
  Timer? _timer;

  static const _items = [
    ('KERNEL_INIT',  'OK',           Color(0xFF00E6C3), 300),
    ('BLE_STACK',    'SEARCHING…',   Color(0xFFFFD700), 900),
    ('ESP32_LINK',   'PENDING',      Color(0xFF3D5166), 1500),
    ('HUD_SYNC',     'WAIT',         Color(0xFF3D5166), 1900),
  ];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    for (int i = 0; i < _items.length; i++) {
      Future.delayed(Duration(milliseconds: _items[i].$4),
          () { if (mounted) setState(() => _visible = i + 1); });
    }
    _timer = Timer.periodic(const Duration(milliseconds: 28), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _progress = (_progress + 0.011).clamp(0.0, 1.0);
        if (_progress >= 1.0) { t.cancel(); Future.delayed(const Duration(milliseconds: 400), _go); }
      });
    });
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const MainShell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() { _fade.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg0,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: Stack(children: [
          const Positioned.fill(child: _GridPaint()),
          // Top-right glow
          Positioned(right: -60, top: -60,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [T.red.withOpacity(0.10), Colors.transparent]),
              )),
          ),
          Center(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SYS_REV', style: T.mono(9, color: T.greyDim)),
                Text('X-99',    style: T.mono(9, color: T.greyDim)),
                const SizedBox(height: 10),
                // Logo
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFF4655), Color(0xFFFF8090)],
                  ).createShader(r),
                  child: Text('V-LINK',
                    style: T.orb(52, color: Colors.white)
                        .copyWith(shadows: [Shadow(color: T.red.withOpacity(0.5), blurRadius: 24)]),
                  ),
                ),
                Text('TACTICAL  HUD', style: T.raj(12, color: T.red).copyWith(letterSpacing: 8)),
                const SizedBox(height: 36),

                // Scan ring
                Center(child: _ScanRing()),
                const SizedBox(height: 36),

                // Boot items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: T.panel(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('INITIALIZING BOOT SEQUENCE',
                        style: T.mono(10, color: T.red)),
                    const SizedBox(height: 12),
                    ..._items.take(_visible).map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 7, height: 7,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: it.$3)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(it.$1, style: T.raj(13, color: T.grey))),
                        Text(it.$2, style: T.mono(10, color: it.$3)),
                      ]),
                    )),
                  ]),
                ),
                const SizedBox(height: 14),

                // Progress bar
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('SYNCING NEURAL LINK', style: T.mono(9, color: T.grey)),
                  Text('${(_progress * 100).round()}%', style: T.mono(10, color: T.red)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: _progress,
                  backgroundColor: T.border,
                  valueColor: const AlwaysStoppedAnimation(T.red),
                  minHeight: 3),
                const SizedBox(height: 18),

                // Console
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: T.panel(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('> V-LINK v2.0.4-STABLE', style: T.mono(10)),
                    const SizedBox(height: 4),
                    Text('> SCANNING FOR LOW ENERGY PERIPHERALS…', style: T.mono(10)),
                    const SizedBox(height: 4),
                    Text('> TARGET: ESP32_HUD_CONTROLLER', style: T.mono(10)),
                    const SizedBox(height: 4),
                    Text('> HANDSHAKE INITIATED…', style: T.mono(10)),
                  ]),
                ),
                const SizedBox(height: 20),

                // Enter button
                GestureDetector(
                  onTap: _go,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: T.bg2, border: Border.all(color: T.border)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.login, color: T.grey, size: 16),
                      const SizedBox(width: 8),
                      Text('ENTER TACTICAL HUD', style: T.raj(14)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('LATENCY', style: T.mono(8, color: T.greyDim)),
                    Text('0.4ms',   style: T.mono(13, color: T.teal)),
                  ],
                )),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// ── Grid background ───────────────────────────────────────────────────────────
class _GridPaint extends StatelessWidget {
  const _GridPaint();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridP(), size: MediaQuery.of(context).size);
}

class _GridP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = T.bg3.withOpacity(0.35)..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Animated scan ring ────────────────────────────────────────────────────────
class _ScanRing extends StatefulWidget {
  @override State<_ScanRing> createState() => _ScanRingState();
}

class _ScanRingState extends State<_ScanRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose()   { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(size: const Size(110, 110), painter: _RingP(_ctrl.value)),
  );
}

class _RingP extends CustomPainter {
  final double t;
  const _RingP(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..color = T.red.withOpacity(0.2)..strokeWidth = 1.5);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, -1.5708 + t * 6.2832, 1.4, false,
        Paint()..style = PaintingStyle.stroke..color = T.red..strokeWidth = 2..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 5, Paint()..color = T.red.withOpacity(0.5 + 0.5 * ((t * 2) % 1.0)));
  }
  @override bool shouldRepaint(_RingP o) => o.t != t;
}

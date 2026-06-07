import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef KeySender = void Function(String key, bool pressed);

class JoystickWidget extends StatefulWidget {
  final double size;
  final bool editMode;
  final KeySender? onKey;

  const JoystickWidget({
    super.key,
    this.size = 140,
    this.editMode = false,
    this.onKey,
  });

  @override
  State<JoystickWidget> createState() => _JoystickState();
}

class _JoystickState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  Offset _knob = Offset.zero;
  bool _active = false;
  String _last = '';

  // Dead-zone radius as fraction of maxR
  static const double _deadFrac = 0.18;

  double get _maxR => widget.size * 0.30;
  double get _deadR => _maxR * _deadFrac;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Offset _clamp(Offset local) {
    final rel = local - Offset(widget.size / 2, widget.size / 2);
    final dist = rel.distance;
    return dist > _maxR ? rel / dist * _maxR : rel;
  }

  void _move(Offset local) {
    final clamped = _clamp(local);
    setState(() {
      _knob = clamped;
      _active = true;
    });

    final nx = clamped.dx / _maxR;
    final ny = clamped.dy / _maxR;

    // Apply dead-zone
    final inDead = clamped.distance < _deadR;
    final keys = inDead
        ? ''
        : [
            if (nx > 0.28) 'D',
            if (nx < -0.28) 'A',
            if (ny < -0.28) 'W',
            if (ny > 0.28) 'S',
          ].join('+');

    if (keys == _last) return;
    for (final k in ['W', 'A', 'S', 'D']) widget.onKey?.call(k, false);
    for (final k in keys.split('+')) {
      if (k.isNotEmpty) widget.onKey?.call(k, true);
    }
    _last = keys;
  }

  void _end() {
    setState(() {
      _knob = Offset.zero;
      _active = false;
    });
    for (final k in ['W', 'A', 'S', 'D']) widget.onKey?.call(k, false);
    _last = '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editMode) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
            painter: _JsPainter(
          knob: Offset.zero,
          active: false,
          editMode: true,
          pulse: 1.0,
          deadR: _deadR,
          maxR: _maxR,
        )),
      );
    }

    return GestureDetector(
      onPanStart: (_) => HapticFeedback.lightImpact(),
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
              painter: _JsPainter(
            knob: _knob,
            active: _active,
            editMode: false,
            pulse: _pulse.value,
            deadR: _deadR,
            maxR: _maxR,
          )),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// JOYSTICK PAINTER — improved visual design
// ══════════════════════════════════════════════════════════════════════════════
class _JsPainter extends CustomPainter {
  final Offset knob;
  final bool active, editMode;
  final double pulse, deadR, maxR;

  const _JsPainter({
    required this.knob,
    required this.active,
    required this.editMode,
    required this.pulse,
    required this.deadR,
    required this.maxR,
  });

  static const Color _accent = Color(0xFFFF4655);
  static const Color _teal = Color(0xFF00E6C3);
  static const Color _ring = Color(0x55FFFFFF);
  static const Color _ringBg = Color(0xAA111820);
  static const Color _dimLine = Color(0x33FFFFFF);
  static const Color _editRing = Color(0xFF00E6C3);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final or = s.width / 2 - 2; // outer ring radius
    final kc = c + knob; // knob centre
    final kr = or * 0.32; // knob radius

    // ── Outer glow (active) ────────────────────────────────────────────────
    if (active) {
      canvas.drawCircle(
          c,
          or + 4,
          Paint()
            ..color = _accent.withOpacity(0.18 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    // ── Outer ring fill ────────────────────────────────────────────────────
    canvas.drawCircle(
        c,
        or,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF1A2330),
            const Color(0xFF0B1117),
          ]).createShader(Rect.fromCircle(center: c, radius: or)));

    // ── Directional zone indicators (N/S/E/W triangles) ───────────────────
    _drawDirIndicators(canvas, c, or, kr);

    // ── Dead-zone circle (subtle) ──────────────────────────────────────────
    canvas.drawCircle(
        c,
        deadR,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _dimLine
          ..strokeWidth = 0.6);

    // ── Outer ring stroke ─────────────────────────────────────────────────
    canvas.drawCircle(
        c,
        or,
        Paint()
          ..style = PaintingStyle.stroke
          ..color =
              editMode ? _editRing : (active ? _accent.withOpacity(0.7) : _ring)
          ..strokeWidth = active ? 1.8 : 1.2);

    // ── Knob shadow/glow ──────────────────────────────────────────────────
    if (active) {
      canvas.drawCircle(
          kc,
          kr + 5,
          Paint()
            ..color = _accent.withOpacity(0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // ── Knob fill (gradient) ───────────────────────────────────────────────
    canvas.drawCircle(
        kc,
        kr,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: active
                ? [_accent.withOpacity(0.5), const Color(0xFF1A2330)]
                : [const Color(0xFF2A3A4A), const Color(0xFF111820)],
          ).createShader(Rect.fromCircle(center: kc, radius: kr)));

    // ── Knob ring ──────────────────────────────────────────────────────────
    canvas.drawCircle(
        kc,
        kr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = active ? _accent : const Color(0x88FFFFFF)
          ..strokeWidth = 1.5);

    // ── Knob crosshair ─────────────────────────────────────────────────────
    final cp = Paint()
      ..color = (active ? Colors.white : const Color(0x88FFFFFF))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final arm = kr * 0.40;
    canvas.drawLine(kc - Offset(arm, 0), kc + Offset(arm, 0), cp);
    canvas.drawLine(kc - Offset(0, arm), kc + Offset(0, arm), cp);

    // ── Centre dot ────────────────────────────────────────────────────────
    if (knob == Offset.zero) {
      canvas.drawCircle(c, 3, Paint()..color = const Color(0x55FFFFFF));
    }
  }

  void _drawDirIndicators(Canvas canvas, Offset c, double or, double kr) {
    final p = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.fill;

    // 4 small triangles pointing inward at N/S/E/W
    const inset = 6.0;
    final tip = or - inset;
    final base = kr + 4.0;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2; // start at top
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -tip)
        ..lineTo(-5, -base)
        ..lineTo(5, -base)
        ..close();
      canvas.drawPath(path, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_JsPainter o) =>
      o.knob != knob || o.active != active || o.pulse != pulse;
}

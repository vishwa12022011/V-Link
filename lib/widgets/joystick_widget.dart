import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

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

class _JoystickState extends State<JoystickWidget> {
  Offset _knob = Offset.zero;
  bool _active = false;
  String _last = '';

  double get _maxR => widget.size * 0.30;
  double get _dead => widget.size * 0.06;

  void _move(Offset local) {
    final rel = local - Offset(widget.size / 2, widget.size / 2);
    final d = rel.distance;
    final clamped = d > _maxR ? rel / d * _maxR : rel;
    setState(() { _knob = clamped; _active = true; });

    final nx = clamped.dx / _maxR;
    final ny = clamped.dy / _maxR;
    final keys = [
      if (nx >  0.25) 'D',
      if (nx < -0.25) 'A',
      if (ny < -0.25) 'W',
      if (ny >  0.25) 'S',
    ].join('+');

    if (keys == _last) return;
    for (final k in ['W','A','S','D']) widget.onKey?.call(k, false);
    for (final k in keys.split('+')) { if (k.isNotEmpty) widget.onKey?.call(k, true); }
    _last = keys;
  }

  void _end() {
    setState(() { _knob = Offset.zero; _active = false; });
    for (final k in ['W','A','S','D']) widget.onKey?.call(k, false);
    _last = '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editMode) {
      return _shell(active: false, editMode: true);
    }
    return GestureDetector(
      onPanStart: (_) { HapticFeedback.lightImpact(); },
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: _shell(active: _active, editMode: false),
    );
  }

  Widget _shell({required bool active, required bool editMode}) => SizedBox(
    width: widget.size, height: widget.size,
    child: CustomPaint(
      painter: _JsPainter(knob: _knob, active: active, editMode: editMode),
    ),
  );
}

class _JsPainter extends CustomPainter {
  final Offset knob;
  final bool active, editMode;
  _JsPainter({required this.knob, required this.active, required this.editMode});

  @override
  void paint(Canvas canvas, Size size) {
    final c  = Offset(size.width / 2, size.height / 2);
    final or = size.width / 2 - 2;
    final kr = size.width * 0.175;

    // Outer ring fill
    canvas.drawCircle(c, or,
        Paint()..color = const Color(0xAA111820));

    // Outer ring stroke
    canvas.drawCircle(c, or,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = editMode ? T.teal
              : active ? const Color(0x88FF4655)
              : const Color(0x44FFFFFF)
          ..strokeWidth = 1.5);

    // Tick marks (8)
    final tick = Paint()..color = const Color(0x33FFFFFF)..strokeWidth = 1;
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        c + Offset(cos(a) * (or - 10), sin(a) * (or - 10)),
        c + Offset(cos(a) * or, sin(a) * or),
        tick,
      );
    }

    // Knob glow
    if (active) {
      canvas.drawCircle(c + knob, kr + 4,
          Paint()
            ..color = T.red.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // Knob fill
    canvas.drawCircle(c + knob, kr,
        Paint()..color = active ? const Color(0xCC1A2330) : const Color(0xAA111820));

    // Knob stroke
    canvas.drawCircle(c + knob, kr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = active ? T.red : const Color(0x66FFFFFF)
          ..strokeWidth = 1.5);

    // Crosshair on knob
    final cp = Paint()..color = const Color(0x88FFFFFF)..strokeWidth = 1.2;
    final kc = c + knob;
    canvas.drawLine(kc - Offset(kr * 0.4, 0), kc + Offset(kr * 0.4, 0), cp);
    canvas.drawLine(kc - Offset(0, kr * 0.4), kc + Offset(0, kr * 0.4), cp);
  }

  @override
  bool shouldRepaint(_JsPainter o) =>
      o.knob != knob || o.active != active || o.editMode != editMode;
}

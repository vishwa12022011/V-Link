import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HudCircleBtn extends StatefulWidget {
  final double size;
  final String iconKey;
  final String keySeq;
  final String bindId;
  final bool editMode;
  final bool isFireBtn;
  final bool isToggleBtn;
  final bool isToggleOn;
  final bool isMuteStyle;
  final Color accentColor;
  final VoidCallback? onPress;
  final VoidCallback? onRelease;
  final VoidCallback? onToggle;

  const HudCircleBtn({
    super.key,
    required this.size,
    required this.iconKey,
    required this.keySeq,
    required this.bindId,
    this.editMode = false,
    this.isFireBtn = false,
    this.isToggleBtn = false,
    this.isToggleOn = false,
    this.isMuteStyle = false,
    this.accentColor = const Color(0xFFFF4655),
    this.onPress,
    this.onRelease,
    this.onToggle,
  });

  @override
  State<HudCircleBtn> createState() => _State();
}

class _State extends State<HudCircleBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 0.84)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent _) {
    if (widget.editMode) return;
    HapticFeedback.mediumImpact();
    setState(() => _down = true);
    _ctrl.forward();
    if (widget.isToggleBtn || widget.isMuteStyle) {
      widget.onToggle?.call();
    } else {
      widget.onPress?.call();
    }
  }

  void _onUp(PointerUpEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    if (!widget.isToggleBtn && !widget.isMuteStyle) widget.onRelease?.call();
  }

  void _onCancel(PointerCancelEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    if (!widget.isToggleBtn && !widget.isMuteStyle) widget.onRelease?.call();
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.size.clamp(28.0, 140.0);
    final accent = widget.accentColor;
    final on = widget.isToggleOn;

    final Color ring, bg, iconCol;
    if (widget.editMode) {
      ring = const Color(0xFF00E6C3);
      bg = const Color(0xAA111820);
      iconCol = const Color(0xCCFFFFFF);
    } else if (widget.isFireBtn) {
      ring = _down ? accent : const Color(0x66FFFFFF);
      bg = _down ? accent : const Color(0xCC1A2330);
      iconCol = Colors.white;
    } else if (on) {
      ring = accent;
      bg = accent.withOpacity(0.25);
      iconCol = Colors.white;
    } else if (_down) {
      ring = accent;
      bg = accent.withOpacity(0.20);
      iconCol = Colors.white;
    } else {
      ring = const Color(0x55FFFFFF);
      bg = const Color(0xAA111820);
      iconCol = const Color(0xCCFFFFFF);
    }

    return Listener(
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: sz,
          height: sz,
          child: CustomPaint(
            painter: _CircleBgP(
                bg: bg,
                ring: ring,
                ringW: widget.editMode ? 1.5 : 1.2,
                glow: _down || on,
                glowColor: accent),
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: sz * 0.56,
                height: sz * 0.56,
                child: CustomPaint(
                  painter:
                      _IconP(iconKey: widget.iconKey, color: iconCol, on: on),
                ),
              ),
              if (widget.isMuteStyle && !on)
                CustomPaint(size: Size(sz, sz), painter: _StrikeP()),
              if (widget.editMode)
                Positioned(
                    top: sz * 0.08,
                    right: sz * 0.08,
                    child: Icon(Icons.open_with,
                        size: sz * 0.22, color: const Color(0xFF00E6C3))),
              if (widget.isToggleBtn && on && !widget.editMode)
                Positioned(
                    bottom: sz * 0.10,
                    child: Container(
                        width: sz * 0.14,
                        height: sz * 0.14,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: accent))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ICON PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class _IconP extends CustomPainter {
  final String iconKey;
  final Color color;
  final bool on;
  const _IconP({required this.iconKey, required this.color, required this.on});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.fill;
    final sp = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * 0.10
      ..style = PaintingStyle.stroke;
    final cx = s.width / 2;
    final cy = s.height / 2;

    switch (iconKey) {
      case 'fire':
        _bullet(canvas, s, cx, cy, p, sp);
        break;
      case 'scope':
        _scope(canvas, s, cx, cy, p, sp);
        break;
      case 'jump':
        _jump(canvas, s, cx, cy, p, sp);
        break;
      case 'crouch':
        _crouch(canvas, s, cx, cy, p, sp);
        break;
      case 'sprint':
        _sprint(canvas, s, cx, cy, p, sp);
        break;
      case 'slide':
        _slide(canvas, s, cx, cy, p, sp);
        break;
      case 'interact':
        _interact(canvas, s, cx, cy, p, sp);
        break; // hand reaching/touching
      case 'quick_melee':
        _punchGlove(canvas, s, cx, cy, p, sp);
        break; // punching glove
      case 'reload':
        _reload(canvas, s, cx, cy, p, sp);
        break;
      case 'ability1':
        _ability1(canvas, s, cx, cy, p, sp);
        break;
      case 'ability2':
        _ability2(canvas, s, cx, cy, p, sp);
        break;
      case 'ultimate':
        _ultimate(canvas, s, cx, cy, p, sp);
        break;
      case 'ability4':
        _ability4(canvas, s, cx, cy, p, sp);
        break; // new 4th ability
      case 'mic':
        _mic(canvas, s, cx, cy, p, sp);
        break;
      case 'speaker':
        _speaker(canvas, s, cx, cy, p, sp);
        break;
      case 'shop':
        _shop(canvas, s, cx, cy, p, sp);
        break;
      case 'emoji':
        _emoji(canvas, s, cx, cy, p, sp);
        break;
      case 'mappin':
        _mapPin(canvas, s, cx, cy, p, sp);
        break;
      case 'settings':
        _settings(canvas, s, cx, cy, p, sp);
        break;
      case 'chat':
        _chat(canvas, s, cx, cy, p, sp);
        break;
      case 'scoreboard':
        _scoreboard(canvas, s, cx, cy, p, sp);
        break;
      default:
        _generic(canvas, s, cx, cy, p);
        break;
    }
  }

  // ── BULLET ────────────────────────────────────────────────────────────────
  void _bullet(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final h = s.height * 0.72;
    final w = s.width * 0.28;
    final r = w / 2;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy + h * 0.10), width: w, height: h * 0.55),
            Radius.circular(r * 0.4)),
        p);
    final tip = Path()
      ..moveTo(cx - r, cy - h * 0.08)
      ..quadraticBezierTo(cx - r, cy - h * 0.48, cx, cy - h * 0.52)
      ..quadraticBezierTo(cx + r, cy - h * 0.48, cx + r, cy - h * 0.08)
      ..close();
    c.drawPath(tip, p);
    c.drawLine(
        Offset(cx - r, cy + h * 0.22),
        Offset(cx + r, cy + h * 0.22),
        Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = s.width * 0.06);
  }

  // ── SCOPE ─────────────────────────────────────────────────────────────────
  void _scope(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final r = s.width * 0.40;
    c.drawCircle(
        Offset(cx, cy),
        r,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.09);
    c.drawLine(Offset(cx - r, cy), Offset(cx + r, cy),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy + r),
        sp..strokeWidth = s.width * 0.07);
    c.drawCircle(Offset(cx, cy), s.width * 0.06, p..style = PaintingStyle.fill);
    c.drawCircle(
        Offset(cx, cy),
        r * 0.35,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.05);
  }

  // ── JUMP ──────────────────────────────────────────────────────────────────
  void _jump(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(Offset(cx, cy - s.height * 0.32), s.width * 0.10,
        p..style = PaintingStyle.fill);
    c.drawLine(Offset(cx, cy - s.height * 0.22),
        Offset(cx, cy + s.height * 0.05), sp..strokeWidth = s.width * 0.09);
    c.drawLine(
        Offset(cx, cy - s.height * 0.10),
        Offset(cx - s.width * 0.28, cy - s.height * 0.22),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx, cy - s.height * 0.10),
        Offset(cx + s.width * 0.28, cy - s.height * 0.22),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx, cy + s.height * 0.05),
        Offset(cx - s.width * 0.20, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx - s.width * 0.20, cy + s.height * 0.30),
        Offset(cx - s.width * 0.06, cy + s.height * 0.44),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx, cy + s.height * 0.05),
        Offset(cx + s.width * 0.20, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx + s.width * 0.20, cy + s.height * 0.30),
        Offset(cx + s.width * 0.06, cy + s.height * 0.44),
        sp..strokeWidth = s.width * 0.07);
  }

  // ── CROUCH ────────────────────────────────────────────────────────────────
  void _crouch(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(Offset(cx, cy - s.height * 0.16), s.width * 0.10,
        p..style = PaintingStyle.fill);
    c.drawLine(
        Offset(cx, cy - s.height * 0.06),
        Offset(cx + s.width * 0.10, cy + s.height * 0.12),
        sp..strokeWidth = s.width * 0.09);
    c.drawLine(
        Offset(cx + s.width * 0.10, cy + s.height * 0.12),
        Offset(cx + s.width * 0.28, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx + s.width * 0.28, cy + s.height * 0.30),
        Offset(cx + s.width * 0.10, cy + s.height * 0.44),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx + s.width * 0.10, cy + s.height * 0.12),
        Offset(cx - s.width * 0.14, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx - s.width * 0.14, cy + s.height * 0.30),
        Offset(cx + s.width * 0.02, cy + s.height * 0.44),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx, cy + s.height * 0.02),
        Offset(cx - s.width * 0.34, cy + s.height * 0.02),
        sp..strokeWidth = s.width * 0.07);
  }

  // ── SPRINT ────────────────────────────────────────────────────────────────
  void _sprint(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(Offset(cx + s.width * 0.06, cy - s.height * 0.30),
        s.width * 0.10, p..style = PaintingStyle.fill);
    c.drawLine(
        Offset(cx + s.width * 0.06, cy - s.height * 0.20),
        Offset(cx - s.width * 0.04, cy + s.height * 0.08),
        sp..strokeWidth = s.width * 0.09);
    c.drawLine(
        Offset(cx + s.width * 0.02, cy - s.height * 0.08),
        Offset(cx + s.width * 0.28, cy - s.height * 0.20),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx + s.width * 0.02, cy - s.height * 0.08),
        Offset(cx - s.width * 0.22, cy + s.height * 0.06),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx - s.width * 0.04, cy + s.height * 0.08),
        Offset(cx + s.width * 0.22, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx + s.width * 0.22, cy + s.height * 0.30),
        Offset(cx + s.width * 0.28, cy + s.height * 0.46),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx - s.width * 0.04, cy + s.height * 0.08),
        Offset(cx - s.width * 0.20, cy + s.height * 0.28),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx - s.width * 0.20, cy + s.height * 0.28),
        Offset(cx - s.width * 0.12, cy + s.height * 0.46),
        sp..strokeWidth = s.width * 0.07);
    final lp = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = s.width * 0.05
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - s.width * 0.42, cy - s.height * 0.04),
        Offset(cx - s.width * 0.28, cy - s.height * 0.04), lp);
    c.drawLine(Offset(cx - s.width * 0.42, cy + s.height * 0.06),
        Offset(cx - s.width * 0.30, cy + s.height * 0.06), lp);
  }

  // ── SLIDE ─────────────────────────────────────────────────────────────────
  void _slide(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(Offset(cx - s.width * 0.22, cy - s.height * 0.10),
        s.width * 0.09, p..style = PaintingStyle.fill);
    c.drawLine(
        Offset(cx - s.width * 0.12, cy - s.height * 0.06),
        Offset(cx + s.width * 0.28, cy + s.height * 0.04),
        sp..strokeWidth = s.width * 0.09);
    c.drawLine(
        Offset(cx + s.width * 0.16, cy + s.height * 0.04),
        Offset(cx + s.width * 0.38, cy + s.height * 0.22),
        sp..strokeWidth = s.width * 0.08);
    c.drawLine(
        Offset(cx + s.width * 0.38, cy + s.height * 0.22),
        Offset(cx + s.width * 0.44, cy + s.height * 0.38),
        sp..strokeWidth = s.width * 0.07);
    c.drawLine(
        Offset(cx + s.width * 0.28, cy + s.height * 0.04),
        Offset(cx + s.width * 0.18, cy + s.height * 0.30),
        sp..strokeWidth = s.width * 0.08);
  }

  // ── INTERACT — hand reaching / touching (index finger extended toward dot) ─
  void _interact(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final hw = s.width * 0.12;
    // Touch point dot (what the finger is reaching toward)
    c.drawCircle(
        Offset(cx, cy - s.height * 0.44),
        s.width * 0.07,
        Paint()
          ..color = color.withOpacity(0.55)
          ..style = PaintingStyle.fill);
    // Ripple
    c.drawCircle(
        Offset(cx, cy - s.height * 0.44),
        s.width * 0.14,
        Paint()
          ..color = color.withOpacity(0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.04);
    // Index finger (pointing up toward dot)
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - s.height * 0.18),
                width: hw * 0.8,
                height: s.height * 0.42),
            Radius.circular(hw * 0.4)),
        p..style = PaintingStyle.fill);
    // Middle finger (shorter)
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + hw * 1.2, cy - s.height * 0.08),
                width: hw * 0.75,
                height: s.height * 0.28),
            Radius.circular(hw * 0.35)),
        p);
    // Ring finger (shorter still)
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + hw * 2.3, cy - s.height * 0.04),
                width: hw * 0.72,
                height: s.height * 0.20),
            Radius.circular(hw * 0.30)),
        p);
    // Palm
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + hw * 0.8, cy + s.height * 0.22),
                width: hw * 3.0,
                height: s.height * 0.26),
            Radius.circular(hw * 0.4)),
        p);
    // Thumb
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx - hw * 0.7, cy + s.height * 0.10),
                width: hw * 0.7,
                height: s.height * 0.18),
            Radius.circular(hw * 0.3)),
        p);
  }

  // ── QUICK MELEE — punching glove ──────────────────────────────────────────
  void _punchGlove(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    // Glove main body (oval fist)
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - s.height * 0.05),
                width: s.width * 0.68,
                height: s.height * 0.52),
            Radius.circular(s.width * 0.18)),
        p..style = PaintingStyle.fill);

    // Thumb
    final thumbPath = Path()
      ..moveTo(cx - s.width * 0.34, cy - s.height * 0.10)
      ..quadraticBezierTo(cx - s.width * 0.48, cy - s.height * 0.20,
          cx - s.width * 0.44, cy + s.height * 0.10)
      ..quadraticBezierTo(cx - s.width * 0.36, cy + s.height * 0.18,
          cx - s.width * 0.28, cy + s.height * 0.08)
      ..close();
    c.drawPath(thumbPath, p);

    // Knuckle lines
    final kp = Paint()
      ..color = const Color(0xFF050A0E).withOpacity(0.35)
      ..strokeWidth = s.width * 0.06
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final x = cx - s.width * 0.14 + i * s.width * 0.14;
      c.drawLine(
          Offset(x, cy - s.height * 0.24), Offset(x, cy - s.height * 0.06), kp);
    }

    // Wrist band
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy + s.height * 0.30),
                width: s.width * 0.58,
                height: s.height * 0.16),
            Radius.circular(s.width * 0.06)),
        Paint()
          ..color = color.withOpacity(0.60)
          ..style = PaintingStyle.fill);

    // Motion lines (punch effect)
    final mp = Paint()
      ..color = color.withOpacity(0.40)
      ..strokeWidth = s.width * 0.05
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx + s.width * 0.38, cy - s.height * 0.20),
        Offset(cx + s.width * 0.50, cy - s.height * 0.20), mp);
    c.drawLine(Offset(cx + s.width * 0.36, cy - s.height * 0.05),
        Offset(cx + s.width * 0.50, cy - s.height * 0.05), mp);
    c.drawLine(Offset(cx + s.width * 0.38, cy + s.height * 0.10),
        Offset(cx + s.width * 0.48, cy + s.height * 0.10), mp);
  }

  
  // ── RELOAD ────────────────────────────────────────────────────────────────
  void _reload(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: s.width * 0.72,
            height: s.height * 0.72),
        -math.pi * 0.7,
        math.pi * 1.6,
        false,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.10);
    final a = -math.pi * 0.7 + math.pi * 1.6;
    final r = s.width * 0.36;
    final tx = cx + r * math.cos(a);
    final ty = cy + r * math.sin(a);
    c.drawPath(
        Path()
          ..moveTo(tx, ty)
          ..lineTo(tx - s.width * 0.14, ty - s.height * 0.06)
          ..lineTo(tx - s.width * 0.06, ty + s.height * 0.14)
          ..close(),
        p..style = PaintingStyle.fill);
  }

  // ── ABILITY 1 (lightning) ─────────────────────────────────────────────────
  void _ability1(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final bolt = Path()
      ..moveTo(cx + s.width * 0.08, cy - s.height * 0.44)
      ..lineTo(cx - s.width * 0.08, cy - s.height * 0.02)
      ..lineTo(cx + s.width * 0.04, cy - s.height * 0.02)
      ..lineTo(cx - s.width * 0.08, cy + s.height * 0.44)
      ..lineTo(cx + s.width * 0.14, cy + s.height * 0.04)
      ..lineTo(cx + s.width * 0.02, cy + s.height * 0.04)
      ..close();
    c.drawPath(bolt, p..style = PaintingStyle.fill);
  }

  // ── ABILITY 2 (target) ────────────────────────────────────────────────────
  void _ability2(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(
        Offset(cx, cy),
        s.width * 0.36,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.09);
    c.drawCircle(Offset(cx, cy), s.width * 0.16, p..style = PaintingStyle.fill);
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tip = Offset(cx + math.cos(a) * s.width * 0.32,
          cy + math.sin(a) * s.height * 0.32);
      final bl = Offset(cx + math.cos(a + 0.4) * s.width * 0.18,
          cy + math.sin(a + 0.4) * s.height * 0.18);
      final br = Offset(cx + math.cos(a - 0.4) * s.width * 0.18,
          cy + math.sin(a - 0.4) * s.height * 0.18);
      c.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(bl.dx, bl.dy)
            ..lineTo(br.dx, br.dy)
            ..close(),
          p);
    }
  }

// ── ABILITY 4 — diamond / orb (distinct from 1/2/3) ───────────────────────
  void _ability4(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    // Diamond shape
    final r = s.width * 0.36;
    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.65, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.65, cy)
      ..close();
    c.drawPath(diamond, p..style = PaintingStyle.fill);
    // Inner shine
    final inner = Path()
      ..moveTo(cx, cy - r * 0.40)
      ..lineTo(cx + r * 0.26, cy - r * 0.10)
      ..lineTo(cx, cy + r * 0.15)
      ..lineTo(cx - r * 0.26, cy - r * 0.10)
      ..close();
    c.drawPath(
        inner,
        Paint()
          ..color = const Color(0xFF050A0E).withOpacity(0.22)
          ..style = PaintingStyle.fill);
  }

  // ── ULTIMATE (star) ───────────────────────────────────────────────────────
  void _ultimate(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final r1 = s.width * 0.40;
    final r2 = s.width * 0.18;
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? r1 : r2;
      final a = i * math.pi / 5 - math.pi / 2;
      i == 0
          ? star.moveTo(cx + r * math.cos(a), cy + r * math.sin(a))
          : star.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
    }
    star.close();
    c.drawPath(star, p..style = PaintingStyle.fill);
  }

  // ── MIC ───────────────────────────────────────────────────────────────────
  void _mic(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - s.height * 0.12),
                width: s.width * 0.30,
                height: s.height * 0.44),
            Radius.circular(s.width * 0.15)),
        p..style = PaintingStyle.fill);
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + s.height * 0.08),
            width: s.width * 0.54,
            height: s.height * 0.36),
        math.pi,
        math.pi,
        false,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.09);
    c.drawLine(Offset(cx, cy + s.height * 0.26),
        Offset(cx, cy + s.height * 0.44), sp..strokeWidth = s.width * 0.09);
    c.drawLine(
        Offset(cx - s.width * 0.14, cy + s.height * 0.44),
        Offset(cx + s.width * 0.14, cy + s.height * 0.44),
        sp..strokeWidth = s.width * 0.09);
  }

  // ── SPEAKER ───────────────────────────────────────────────────────────────
  void _speaker(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final cone = Path()
      ..moveTo(cx - s.width * 0.10, cy - s.height * 0.18)
      ..lineTo(cx - s.width * 0.26, cy - s.height * 0.30)
      ..lineTo(cx - s.width * 0.26, cy + s.height * 0.30)
      ..lineTo(cx - s.width * 0.10, cy + s.height * 0.18)
      ..close();
    c.drawPath(cone, p..style = PaintingStyle.fill);
    c.drawRect(
        Rect.fromCenter(
            center: Offset(cx - s.width * 0.02, cy),
            width: s.width * 0.16,
            height: s.height * 0.36),
        p);
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx + s.width * 0.06, cy),
            width: s.width * 0.28,
            height: s.height * 0.28),
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        sp..strokeWidth = s.width * 0.08);
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx + s.width * 0.06, cy),
            width: s.width * 0.46,
            height: s.height * 0.46),
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        sp..strokeWidth = s.width * 0.07);
  }

  // ── SHOP ──────────────────────────────────────────────────────────────────
  void _shop(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy + s.height * 0.06),
                width: s.width * 0.62,
                height: s.height * 0.52),
            Radius.circular(s.width * 0.08)),
        p..style = PaintingStyle.fill);
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy - s.height * 0.16),
            width: s.width * 0.32,
            height: s.height * 0.24),
        math.pi,
        math.pi,
        false,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.09);
  }

  // ── EMOJI ─────────────────────────────────────────────────────────────────
  void _emoji(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(
        Offset(cx, cy),
        s.width * 0.38,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.08);
    c.drawCircle(Offset(cx - s.width * 0.12, cy - s.height * 0.10),
        s.width * 0.06, p..style = PaintingStyle.fill);
    c.drawCircle(
        Offset(cx + s.width * 0.12, cy - s.height * 0.10), s.width * 0.06, p);
    c.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + s.height * 0.04),
            width: s.width * 0.30,
            height: s.height * 0.22),
        0,
        math.pi,
        false,
        sp
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.08);
  }

  // ── MAP PIN ───────────────────────────────────────────────────────────────
  void _mapPin(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final pin = Path()
      ..moveTo(cx, cy + s.height * 0.44)
      ..lineTo(cx - s.width * 0.28, cy - s.height * 0.10)
      ..arcToPoint(Offset(cx + s.width * 0.28, cy - s.height * 0.10),
          radius: Radius.circular(s.width * 0.28), clockwise: false)
      ..close();
    c.drawPath(pin, p..style = PaintingStyle.fill);
    c.drawCircle(
        Offset(cx, cy - s.height * 0.10),
        s.width * 0.12,
        Paint()
          ..color = const Color(0xFF050A0E)
          ..style = PaintingStyle.fill);
  }

  // ── SETTINGS ─────────────────────────────────────────────────────────────
  void _settings(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawCircle(Offset(cx, cy), s.width * 0.16, p..style = PaintingStyle.fill);
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + math.cos(a) * s.width * 0.28,
                      cy + math.sin(a) * s.height * 0.28),
                  width: s.width * 0.12,
                  height: s.height * 0.16),
              Radius.circular(s.width * 0.03)),
          p);
    }
    c.drawCircle(
        Offset(cx, cy),
        s.width * 0.10,
        Paint()
          ..color = const Color(0xFF050A0E)
          ..style = PaintingStyle.fill);
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────
  void _chat(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy - s.height * 0.05),
                width: s.width * 0.70,
                height: s.height * 0.50),
            Radius.circular(s.width * 0.12)),
        p..style = PaintingStyle.fill);
    c.drawPath(
        Path()
          ..moveTo(cx - s.width * 0.10, cy + s.height * 0.20)
          ..lineTo(cx - s.width * 0.24, cy + s.height * 0.42)
          ..lineTo(cx + s.width * 0.06, cy + s.height * 0.20),
        p);
    final lp = Paint()
      ..color = const Color(0xFF050A0E)
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - s.width * 0.22, cy - s.height * 0.10),
        Offset(cx + s.width * 0.22, cy - s.height * 0.10), lp);
    c.drawLine(Offset(cx - s.width * 0.18, cy + s.height * 0.04),
        Offset(cx + s.width * 0.10, cy + s.height * 0.04), lp);
  }

  // ── SCOREBOARD ────────────────────────────────────────────────────────────
  void _scoreboard(Canvas c, Size s, double cx, double cy, Paint p, Paint sp) {
    final heights = [0.60, 0.40, 0.28];
    final offsets = [-s.width * 0.18, 0.0, s.width * 0.18];
    for (int i = 0; i < 3; i++) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  cx + offsets[i] - s.width * 0.09,
                  cy + s.height * 0.44 - s.height * heights[i],
                  s.width * 0.18,
                  s.height * heights[i]),
              Radius.circular(s.width * 0.03)),
          p..style = PaintingStyle.fill);
    }
  }

  // ── GENERIC ───────────────────────────────────────────────────────────────
  void _generic(Canvas c, Size s, double cx, double cy, Paint p) {
    c.drawCircle(
        Offset(cx, cy),
        s.width * 0.30,
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * 0.08);
    c.drawCircle(Offset(cx, cy), s.width * 0.10, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_IconP o) =>
      o.iconKey != iconKey || o.color != color || o.on != on;
}

// ══════════════════════════════════════════════════════════════════════════════
// CIRCLE BACKGROUND PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class _CircleBgP extends CustomPainter {
  final Color bg, ring, glowColor;
  final double ringW;
  final bool glow;
  const _CircleBgP(
      {required this.bg,
      required this.ring,
      required this.ringW,
      required this.glow,
      required this.glowColor});

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 1;
    if (glow)
      canvas.drawCircle(
          c,
          r + 6,
          Paint()
            ..color = glowColor.withOpacity(0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(c, r, Paint()..color = bg);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = ring
          ..strokeWidth = ringW);
  }

  @override
  bool shouldRepaint(_CircleBgP o) =>
      o.bg != bg || o.ring != ring || o.glow != glow;
}

// ══════════════════════════════════════════════════════════════════════════════
// STRIKETHROUGH (mic/speaker off)
// ══════════════════════════════════════════════════════════════════════════════
class _StrikeP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawLine(
        Offset(s.width * 0.25, s.height * 0.25),
        Offset(s.width * 0.75, s.height * 0.75),
        Paint()
          ..color = const Color(0xCCFF4655)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_) => false;
}

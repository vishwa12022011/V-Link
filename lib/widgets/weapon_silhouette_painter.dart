import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// Draws a weapon silhouette on canvas.
/// All silhouettes are pure geometric shapes — no images needed.
/// style: 'active'   → horizontal, facing left, full body
///        'inactive' → slanted upward ~30°, compact silhouette
class WeaponSilhouettePainter extends CustomPainter {
  final WeaponType type;
  final Color      color;
  final bool       active; // true = big box, false = small slot

  const WeaponSilhouettePainter({
    required this.type,
    required this.color,
    this.active = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..style       = PaintingStyle.fill
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    if (active) {
      // Horizontal layout, centred, facing left
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      _drawActive(canvas, size, paint);
      canvas.restore();
    } else {
      // Slanted upward ~30 degrees, compact
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(-math.pi / 6); // -30°
      _drawInactive(canvas, size, paint);
      canvas.restore();
    }
  }

  void _drawActive(Canvas canvas, Size size, Paint p) {
    final s = size.shortestSide * 0.55;
    switch (type) {
      case WeaponType.primary:  _ak47Active(canvas, s, p);  break;
      case WeaponType.pistol:   _deagleActive(canvas, s, p); break;
      case WeaponType.grenade:  _grenadeActive(canvas, s, p); break;
      case WeaponType.knife:    _knifeActive(canvas, s, p);  break;
    }
  }

  void _drawInactive(Canvas canvas, Size size, Paint p) {
    final s = size.shortestSide * 0.42;
    switch (type) {
      case WeaponType.primary:  _ak47Inactive(canvas, s, p);  break;
      case WeaponType.pistol:   _deagleInactive(canvas, s, p); break;
      case WeaponType.grenade:  _grenadeInactive(canvas, s, p); break;
      case WeaponType.knife:    _knifeInactive(canvas, s, p);  break;
    }
  }

  // ── AK-47 ──────────────────────────────────────────────────────────────────
  void _ak47Active(Canvas canvas, double s, Paint p) {
    // Main body / receiver
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.05, 0), width: s*1.4, height: s*0.18),
      Radius.circular(s*0.04),
    ), p);
    // Barrel
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.72, -s*0.04), width: s*0.55, height: s*0.07),
      Radius.circular(s*0.02),
    ), p);
    // Stock
    final stockPath = Path()
      ..moveTo(s*0.62, -s*0.09)
      ..lineTo(s*0.85, -s*0.22)
      ..lineTo(s*0.90, -s*0.18)
      ..lineTo(s*0.90,  s*0.10)
      ..lineTo(s*0.62,  s*0.10)
      ..close();
    canvas.drawPath(stockPath, p);
    // Magazine (curved, pointing down)
    final magPath = Path()
      ..moveTo(-s*0.05,  s*0.09)
      ..quadraticBezierTo(-s*0.12,  s*0.42, -s*0.18,  s*0.45)
      ..lineTo(-s*0.02,  s*0.45)
      ..quadraticBezierTo( s*0.04,  s*0.42,  s*0.08,  s*0.09)
      ..close();
    canvas.drawPath(magPath, p);
    // Grip
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s*0.22, s*0.26), width: s*0.14, height: s*0.28),
      Radius.circular(s*0.04),
    ), p);
    // Front grip
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.32, s*0.24), width: s*0.10, height: s*0.22),
      Radius.circular(s*0.03),
    ), p);
  }

  void _ak47Inactive(Canvas canvas, double s, Paint p) {
    // Simplified side view
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s*1.6, height: s*0.20),
      Radius.circular(s*0.04),
    ), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.65, -s*0.05), width: s*0.45, height: s*0.08),
      Radius.circular(s*0.02),
    ), p);
    // Magazine stub
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.05, s*0.22), width: s*0.12, height: s*0.28),
      Radius.circular(s*0.03),
    ), p);
  }

  // ── Desert Eagle ───────────────────────────────────────────────────────────
  void _deagleActive(Canvas canvas, double s, Paint p) {
    // Slide / upper body
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.15, -s*0.05), width: s*0.85, height: s*0.20),
      Radius.circular(s*0.05),
    ), p);
    // Barrel extension
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(-s*0.56, -s*0.04), width: s*0.16, height: s*0.08),
      Radius.circular(s*0.02),
    ), p);
    // Grip / handle
    final gripPath = Path()
      ..moveTo(s*0.10, -s*0.05)
      ..lineTo(s*0.30, -s*0.05)
      ..lineTo(s*0.34,  s*0.38)
      ..lineTo(s*0.08,  s*0.38)
      ..close();
    canvas.drawPath(gripPath, p);
    // Trigger guard
    canvas.drawArc(
      Rect.fromCenter(center: Offset(s*0.06, s*0.12), width: s*0.30, height: s*0.30),
      0, math.pi, false,
      Paint()..color = p.color..style = PaintingStyle.stroke..strokeWidth = s*0.05,
    );
  }

  void _deagleInactive(Canvas canvas, double s, Paint p) {
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s*1.0, height: s*0.22),
      Radius.circular(s*0.05),
    ), p);
    final gripPath = Path()
      ..moveTo(s*0.22, -s*0.11)
      ..lineTo(s*0.38, -s*0.11)
      ..lineTo(s*0.40,  s*0.28)
      ..lineTo(s*0.20,  s*0.28)
      ..close();
    canvas.drawPath(gripPath, p);
  }

  // ── Grenade ────────────────────────────────────────────────────────────────
  void _grenadeActive(Canvas canvas, double s, Paint p) {
    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s*0.05), width: s*0.55, height: s*0.70),
      p,
    );
    // Top neck
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -s*0.38), width: s*0.18, height: s*0.16),
      Radius.circular(s*0.04),
    ), p);
    // Pin lever
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s*0.22, -s*0.38), width: s*0.28, height: s*0.07),
      Radius.circular(s*0.02),
    ), p);
    // Pin ring
    canvas.drawCircle(Offset(s*0.36, -s*0.38), s*0.10,
        Paint()..color = p.color..style = PaintingStyle.stroke..strokeWidth = s*0.06);
    // Segment lines
    final lp = Paint()
      // FIXED: withValues(alpha: ...)
      ..color = p.color.withValues(alpha: 0.4)
      ..strokeWidth = s*0.03
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-s*0.27, 0), Offset(s*0.27, 0), lp);
    canvas.drawLine(Offset(0, -s*0.28), Offset(0, s*0.38), lp);
  }

  void _grenadeInactive(Canvas canvas, double s, Paint p) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s*0.60, height: s*0.80),
      p,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -s*0.46), width: s*0.18, height: s*0.14),
      Radius.circular(s*0.03),
    ), p);
  }

  // ── Knife ──────────────────────────────────────────────────────────────────
  void _knifeActive(Canvas canvas, double s, Paint p) {
    // Blade
    final bladePath = Path()
      ..moveTo(-s*0.65,  s*0.04)
      ..lineTo( s*0.30, -s*0.10)
      ..lineTo( s*0.30,  s*0.04)
      ..lineTo(-s*0.65,  s*0.16)
      ..close();
    canvas.drawPath(bladePath, p);
    // Guard
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s*0.30, s*0.02), width: s*0.06, height: s*0.30),
      Radius.circular(s*0.02),
    ), p);
    // Handle
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s*0.58, s*0.02), width: s*0.50, height: s*0.22),
      Radius.circular(s*0.06),
    ), p);
  }

  void _knifeInactive(Canvas canvas, double s, Paint p) {
    final bladePath = Path()
      ..moveTo(-s*0.72,  s*0.04)
      ..lineTo( s*0.28, -s*0.10)
      ..lineTo( s*0.28,  s*0.04)
      ..lineTo(-s*0.72,  s*0.16)
      ..close();
    canvas.drawPath(bladePath, p);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(s*0.55, s*0.04), width: s*0.44, height: s*0.20),
      Radius.circular(s*0.05),
    ), p);
  }

  @override
  bool shouldRepaint(WeaponSilhouettePainter o) =>
      o.type != type || o.color != color || o.active != active;
}
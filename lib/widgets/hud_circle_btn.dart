import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// A single circular HUD button that matches the Free-Fire / Valorant aesthetic:
///  • Dark translucent background
///  • White icon + optional label
///  • Red glow / fill on press
///  • Scales down on press (80 ms)
///  • In edit mode → shows drag-handles & teal border
class HudCircleBtn extends StatefulWidget {
  final double size;
  final IconData icon;
  final String? label;         // small text under icon (optional)
  final String keySeq;
  final bool editMode;
  final bool isFireBtn;        // fire button gets special treatment
  final VoidCallback? onPress;
  final VoidCallback? onRelease;

  const HudCircleBtn({
    super.key,
    required this.size,
    required this.icon,
    required this.keySeq,
    this.label,
    this.editMode = false,
    this.isFireBtn = false,
    this.onPress,
    this.onRelease,
  });

  @override
  State<HudCircleBtn> createState() => _HudCircleBtnState();
}

class _HudCircleBtnState extends State<HudCircleBtn>
    with SingleTickerProviderStateMixin {
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _down_(PointerDownEvent _) {
    if (widget.editMode) return;
    HapticFeedback.mediumImpact();
    setState(() => _down = true);
    _ctrl.forward();
    widget.onPress?.call();
  }

  void _up_(PointerUpEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    widget.onRelease?.call();
  }

  void _cancel_(PointerCancelEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    widget.onRelease?.call();
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.size.clamp(28.0, 140.0);

    // Colours
    final ringColor = widget.editMode
        ? T.teal
        : _down
            ? T.red
            : const Color(0x55FFFFFF);

    final bgColor = widget.isFireBtn
        ? (_down ? T.red : const Color(0xCC1A2330))
        : (_down ? const Color(0xBBFF4655) : const Color(0xAA111820));

    final iconColor = _down ? Colors.white : const Color(0xDDFFFFFF);

    return Listener(
      onPointerDown: _down_,
      onPointerUp: _up_,
      onPointerCancel: _cancel_,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: sz, height: sz,
          child: CustomPaint(
            painter: _CirclePainter(
              bg: bgColor,
              ring: ringColor,
              ringWidth: widget.editMode ? 1.5 : 1.2,
              glow: _down,
              glowColor: widget.isFireBtn ? T.red : T.red.withOpacity(0.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon,
                    size: sz * (widget.label != null ? 0.38 : 0.44),
                    color: iconColor),
                if (widget.label != null && sz > 50) ...[
                  const SizedBox(height: 2),
                  Text(widget.label!,
                      style: T.mono(sz * 0.13, color: iconColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (widget.editMode)
                  Positioned(
                    top: 2, right: 2,
                    child: Icon(Icons.open_with,
                        size: sz * 0.18, color: T.teal),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color bg, ring, glowColor;
  final double ringWidth;
  final bool glow;

  const _CirclePainter({
    required this.bg, required this.ring,
    required this.ringWidth, required this.glow,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 1;

    // Glow bloom
    if (glow) {
      canvas.drawCircle(c, r + 6,
          Paint()
            ..color = glowColor.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    // Fill
    canvas.drawCircle(c, r, Paint()..color = bg);

    // Ring
    canvas.drawCircle(
      c, r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = ring
        ..strokeWidth = ringWidth,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter o) =>
      o.bg != bg || o.ring != ring || o.glow != glow;
}

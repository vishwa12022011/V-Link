import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HudCircleBtn extends StatefulWidget {
  final double   size;
  final IconData icon;
  final String   keySeq;
  final String   bindId;
  final bool     editMode;
  final bool     isFireBtn;
  final bool     isToggleBtn;
  final bool     isToggleOn;
  final bool     isMuteStyle;
  final Color    accentColor;
  final VoidCallback? onPress;
  final VoidCallback? onRelease;
  final VoidCallback? onToggle;

  const HudCircleBtn({
    super.key,
    required this.size,
    required this.icon,
    required this.keySeq,
    required this.bindId,
    this.editMode    = false,
    this.isFireBtn   = false,
    this.isToggleBtn = false,
    this.isToggleOn  = false,
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
  late Animation<double>   _scale;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
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
    if (widget.isToggleBtn || widget.isMuteStyle) {
      widget.onToggle?.call();
    } else {
      widget.onPress?.call();
    }
  }

  void _up_(PointerUpEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    if (!widget.isToggleBtn && !widget.isMuteStyle) widget.onRelease?.call();
  }

  void _cancel_(PointerCancelEvent _) {
    if (widget.editMode) return;
    setState(() => _down = false);
    _ctrl.reverse();
    if (!widget.isToggleBtn && !widget.isMuteStyle) widget.onRelease?.call();
  }

  @override
  Widget build(BuildContext context) {
    final sz     = widget.size.clamp(28.0, 140.0);
    final accent = widget.accentColor;
    final on     = widget.isToggleOn;

    final Color ring, bg, iconCol;
    if (widget.editMode) {
      ring    = const Color(0xFF00E6C3);
      bg      = const Color(0xAA111820);
      iconCol = const Color(0xCCFFFFFF);
    } else if (widget.isFireBtn) {
      ring    = _down ? accent : const Color(0x55FFFFFF);
      bg      = _down ? accent : const Color(0xCC1A2330);
      iconCol = Colors.white;
    } else if (on) {
      ring    = accent;
      bg      = accent.withOpacity(0.25);
      iconCol = Colors.white;
    } else if (_down) {
      ring    = accent;
      bg      = accent.withOpacity(0.20);
      iconCol = Colors.white;
    } else {
      ring    = const Color(0x55FFFFFF);
      bg      = const Color(0xAA111820);
      iconCol = const Color(0xCCFFFFFF);
    }

    return Listener(
      onPointerDown: _down_, onPointerUp: _up_, onPointerCancel: _cancel_,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: sz, height: sz,
          child: CustomPaint(
            painter: _CircleP(bg: bg, ring: ring, ringW: widget.editMode ? 1.5 : 1.2,
                glow: _down || on, glowCol: accent),
            child: Stack(alignment: Alignment.center, children: [
              Icon(widget.icon, size: sz * 0.40, color: iconCol),
              if (widget.isMuteStyle && !on)
                CustomPaint(size: Size(sz, sz), painter: _StrikeP()),
              if (widget.editMode)
                Positioned(top: sz * 0.08, right: sz * 0.08,
                    child: Icon(Icons.open_with,
                        size: sz * 0.22, color: const Color(0xFF00E6C3))),
              if (widget.isToggleBtn && on && !widget.editMode)
                Positioned(bottom: sz * 0.10,
                    child: Container(width: sz * 0.14, height: sz * 0.14,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accent))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CircleP extends CustomPainter {
  final Color bg, ring, glowCol;
  final double ringW;
  final bool glow;
  const _CircleP({required this.bg, required this.ring, required this.ringW,
      required this.glow, required this.glowCol});

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 1;
    if (glow) canvas.drawCircle(c, r + 6,
        Paint()..color = glowCol.withOpacity(0.30)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(c, r, Paint()..color = bg);
    canvas.drawCircle(c, r,
        Paint()..style = PaintingStyle.stroke..color = ring..strokeWidth = ringW);
  }

  @override bool shouldRepaint(_CircleP o) => o.bg != bg || o.ring != ring || o.glow != glow;
}

class _StrikeP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawLine(
      Offset(s.width * 0.25, s.height * 0.25),
      Offset(s.width * 0.75, s.height * 0.75),
      Paint()..color = const Color(0xCCFF4655)..strokeWidth = 2.0..strokeCap = StrokeCap.round,
    );
  }
  @override bool shouldRepaint(_) => false;
}

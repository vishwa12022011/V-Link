import 'package:flutter/material.dart';

class T {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color bg0 = Color(0xFF050A0E);
  static const Color bg1 = Color(0xFF0B1117);
  static const Color bg2 = Color(0xFF111820);
  static const Color bg3 = Color(0xFF1A2330);
  static const Color bg4 = Color(0xFF212E3D);

  static const Color red = Color(0xFFFF4655);
  static const Color redDim = Color(0xFF7A1E26);
  static const Color teal = Color(0xFF00E6C3);
  static const Color tealDim = Color(0xFF00413A);
  static const Color gold = Color(0xFFFFD700);

  static const Color white = Color(0xFFECF0F1);
  static const Color grey = Color(0xFF8A9BB0);
  static const Color greyDim = Color(0xFF3D5166);
  static const Color border = Color(0xFF1E3045);
  static const Color borderHi = Color(0xFFFF4655);

  // ── Typography ────────────────────────────────────────────────────────────
  static TextStyle orb(double sz,
          {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(
          fontFamily: 'Orbitron',
          fontSize: sz,
          fontWeight: w,
          color: color,
          letterSpacing: sz * 0.12);

  static TextStyle raj(double sz,
          {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: sz,
          fontWeight: w,
          color: color,
          letterSpacing: sz * 0.08);

  static TextStyle mono(double sz, {Color color = teal}) => TextStyle(
      fontFamily: 'ShareTechMono',
      fontSize: sz,
      color: color,
      letterSpacing: 0.4);

  // ── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration panel({bool active = false}) => BoxDecoration(
        color: bg1,
        border:
            Border.all(color: active ? red : border, width: active ? 1.5 : 1),
      );

  static BoxDecoration redAccentPanel() => BoxDecoration(
        color: bg2,
        border: Border(
          left: BorderSide(color: red, width: 3),
          top: BorderSide(color: border),
          right: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      );

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg0,
        primaryColor: red,
        colorScheme: const ColorScheme.dark(
          primary: red,
          secondary: teal,
          surface: bg1,
          background: bg0,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: red,
          inactiveTrackColor: border,
          thumbColor: red,
          overlayColor: Color(0x33FF4655),
          trackHeight: 3,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
              (s) => s.contains(MaterialState.selected) ? red : greyDim),
          trackColor: MaterialStateProperty.resolveWith(
              (s) => s.contains(MaterialState.selected) ? redDim : bg3),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// VHEADER — uses MediaQuery safe area so it never overlaps system bars
// ══════════════════════════════════════════════════════════════════════════════
class VHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? trailing;

  const VHeader({
    super.key,
    required this.title,
    this.sub,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery top padding (safe area) + small fixed inset.
    // When system bars are hidden (immersiveSticky) top = 0, so this becomes
    // just 12px top padding — compact and correct in both portrait and landscape.
    final topPad = MediaQuery.of(context).padding.top + 12;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 16),
      decoration: const BoxDecoration(
        color: T.bg1,
        border: Border(bottom: BorderSide(color: T.border)),
      ),
      child: Row(children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: T.orb(18)),
            if (sub != null) ...[
              const SizedBox(height: 4),
              Text(sub!, style: T.mono(10, color: T.red)),
            ],
          ],
        )),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ── Status pill ────────────────────────────────────────────────────────────────
class VPill extends StatelessWidget {
  final String label;
  final Color color;
  const VPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color),
        ),
        child: Text(label, style: T.mono(10, color: color)),
      );
}

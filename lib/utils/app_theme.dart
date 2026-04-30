import 'package:flutter/material.dart';

class T {
  // ── Core palette ─────────────────────────────────────────────────────────
  static const Color bg0      = Color(0xFF050A0E);
  static const Color bg1      = Color(0xFF0B1117);
  static const Color bg2      = Color(0xFF111820);
  static const Color bg3      = Color(0xFF1A2330);
  static const Color bg4      = Color(0xFF212E3D);

  static const Color red      = Color(0xFFFF4655);   // Valorant red
  static const Color redDim   = Color(0xFF7A1E26);
  static const Color teal     = Color(0xFF00E6C3);
  static const Color tealDim  = Color(0xFF00413A);
  static const Color gold     = Color(0xFFFFD700);

  static const Color white    = Color(0xFFECF0F1);
  static const Color grey     = Color(0xFF8A9BB0);
  static const Color greyDim  = Color(0xFF3D5166);
  static const Color border   = Color(0xFF1E3045);
  static const Color borderHi = Color(0xFFFF4655);

  // ── HUD colours ───────────────────────────────────────────────────────────
  static const Color hudBtnBg     = Color(0xCC1A2330);  // semi-transparent
  static const Color hudBtnStroke = Color(0x99FFFFFF);
  static const Color hudBtnActive = Color(0xCCFF4655);

  // ── Type ──────────────────────────────────────────────────────────────────
  static TextStyle orb(double sz, {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(fontFamily: 'Orbitron', fontSize: sz, fontWeight: w, color: color, letterSpacing: sz * 0.12);

  static TextStyle raj(double sz, {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(fontFamily: 'Rajdhani', fontSize: sz, fontWeight: w, color: color, letterSpacing: sz * 0.08);

  static TextStyle mono(double sz, {Color color = teal}) =>
      TextStyle(fontFamily: 'ShareTechMono', fontSize: sz, color: color, letterSpacing: 0.4);

  // ── Decorations ───────────────────────────────────────────────────────────
  static BoxDecoration panel({bool active = false}) => BoxDecoration(
    color: bg1,
    border: Border.all(color: active ? red : border, width: active ? 1.5 : 1),
  );

  static BoxDecoration redAccentPanel() => BoxDecoration(
    color: bg2,
    border: Border(
      left:   BorderSide(color: red, width: 3),
      top:    BorderSide(color: border),
      right:  BorderSide(color: border),
      bottom: BorderSide(color: border),
    ),
  );

  // ── Theme ────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg0,
    primaryColor: red,
    colorScheme: const ColorScheme.dark(
      primary: red, secondary: teal,
      surface: bg1, background: bg0,
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

// ── Reusable scaffold header ───────────────────────────────────────────────
class VHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? trailing;
  const VHeader({super.key, required this.title, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        color: T.bg1,
        border: Border(bottom: BorderSide(color: T.border)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.orb(18)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: T.mono(10, color: T.red)),
          ],
        ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

// ── Pill status indicator ─────────────────────────────────────────────────
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

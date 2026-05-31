import 'package:flutter/material.dart';

class T {
  static const Color bg0      = Color(0xFF050A0E);
  static const Color bg1      = Color(0xFF0B1117);
  static const Color bg2      = Color(0xFF111820);
  static const Color bg3      = Color(0xFF1A2330);
  static const Color bg4      = Color(0xFF212E3D);

  // Core UI Accents
  static const Color red      = Color(0xFFFF4655);
  static const Color redDim   = Color(0xFF7A1E26);
  static const Color teal     = Color(0xFF00E6C3);
  static const Color tealDim  = Color(0xFF00413A);

  // New Custom Premium Artifact Palette
  static const Color gold     = Color(0xFF3B08C6); 
  static const Color emerald  = Color(0xFF518563); 
  static const Color sapphire = Color(0xFF566A85); 
  static const Color ruby     = Color(0xFF854650); 

  static const Color white    = Color(0xFFECF0F1);
  static const Color grey     = Color(0xFF8A9BB0);
  static const Color greyDim  = Color(0xFF3D5166);
  static const Color border   = Color(0xFF1E3045);
  static const Color borderHi = Color(0xFFFF4655);

  static TextStyle h1 = orb(18);
  static TextStyle h2 = mono(10, color: red);

  static TextStyle orb(double sz,
          {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(
          fontFamily: 'Orbitron', fontSize: sz, fontWeight: w,
          color: color, letterSpacing: sz * 0.12);

  static TextStyle raj(double sz,
          {Color color = white, FontWeight w = FontWeight.w700}) =>
      TextStyle(
          fontFamily: 'Rajdhani', fontSize: sz, fontWeight: w,
          color: color, letterSpacing: sz * 0.08);

  static TextStyle mono(double sz, {Color color = teal}) =>
      TextStyle(fontFamily: 'ShareTechMono', fontSize: sz,
          color: color, letterSpacing: 0.4);

  static BoxDecoration panel({bool active = false}) => BoxDecoration(
        color:  bg1,
        border: Border.all(color: active ? red : border, width: active ? 1.5 : 1),
      );

  static BoxDecoration redAccentPanel() => BoxDecoration(
        color:  bg2,
        border: Border(
          left:   BorderSide(color: red,    width: 3),
          top:    BorderSide(color: border),
          right:  BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness:            Brightness.dark,
        scaffoldBackgroundColor: bg0,
        primaryColor:          red,
        colorScheme: const ColorScheme.dark(
          primary: red, secondary: teal, surface: bg1,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor:   red,
          inactiveTrackColor: border,
          thumbColor:         red,
          overlayColor:       Color(0x33FF4655),
          trackHeight:        3,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? red : greyDim),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? redDim : bg3),
        ),
      );
}

class VPill extends StatelessWidget {
  final String label;
  final Color  color;
  const VPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:  color.withValues(alpha: 0.12),
          border: Border.all(color: color),
        ),
        child: Text(label, style: T.mono(10, color: color)),
      );
}
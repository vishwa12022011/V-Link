import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Bottom sheet colour picker with preset palette + HSV slider + HEX input
class ColorPickerSheet extends StatefulWidget {
  final Color   initial;
  final void Function(Color, String) onChanged; // color, hex

  const ColorPickerSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  // Preset array swapped to include your premium desaturated fantasy palette
  static const _palette = [
    Color(0xFFFF4655), // Valorant red
    Color(0xFF3B08C6), // Premium Gold
    Color(0xFF518563), // Emerald
    Color(0xFF566A85), // Sapphire
    Color(0xFF854650), // Ruby
    Color(0xFF00E6C3), // Original Teal
    Color(0xFFFFFFFF), // White
  ];

  late Color   _current;
  late double  _hue, _sat, _val;
  late TextEditingController _hexCtrl;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    final hsv = HSVColor.fromColor(_current);
    _hue = hsv.hue; _sat = hsv.saturation; _val = hsv.value;
    _hexCtrl = TextEditingController(text: _colorToHex(_current));
  }

  @override
  void dispose() { _hexCtrl.dispose(); super.dispose(); }

  String _colorToHex(Color c) {
    // Uses the precise math conversions recommended by the compiler warnings
    final int r = (c.r * 255.0).round() & 0xff;
    final int g = (c.g * 255.0).round() & 0xff;
    final int b = (c.b * 255.0).round() & 0xff;
    
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Color _fromHSV() => HSVColor.fromAHSV(1.0, _hue, _sat, _val).toColor();

  void _applyColor(Color c) {
    setState(() {
      _current = c;
      final hsv = HSVColor.fromColor(c);
      _hue = hsv.hue; _sat = hsv.saturation; _val = hsv.value;
      _hexCtrl.text = _colorToHex(c);
      _hexError = false;
    });
    widget.onChanged(c, _colorToHex(c));
  }

  void _onHexSubmit(String raw) {
    try {
      final hex = raw.replaceAll('#', '').trim();
      if (hex.length != 6) throw Exception();
      final c = Color(int.parse('FF$hex', radix: 16));
      _applyColor(c);
    } catch (_) {
      setState(() => _hexError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      color: T.bg1,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Handle bar
        Center(child: Container(width: 40, height: 3, color: T.border,
            margin: const EdgeInsets.only(bottom: 16))),

        Text('ACCENT COLOUR', style: T.orb(14)),
        const SizedBox(height: 4),
        Text('Select from palette, drag slider, or enter HEX',
            style: T.mono(9, color: T.grey)),
        const SizedBox(height: 16),

        // Palette chips
        Wrap(spacing: 10, runSpacing: 10,
          children: _palette.map((c) {
            // Replaced deprecated .value checking with direct color object validation
            final sel = c == _current;
            return GestureDetector(
              onTap: () => _applyColor(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: c,
                  border: Border.all(
                    color: sel ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8)] : [],
                ),
                child: sel
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Hue slider
        Text('HUE', style: T.mono(9, color: T.grey)),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: Stack(children: [
            Positioned.fill(child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(painter: _HueBarPainter()),
            )),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
              ),
              child: Slider(
                value: _hue, min: 0, max: 360,
                onChanged: (v) {
                  setState(() { _hue = v; _current = _fromHSV(); _hexCtrl.text = _colorToHex(_current); });
                  widget.onChanged(_current, _colorToHex(_current));
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Saturation slider
        Text('SATURATION', style: T.mono(9, color: T.grey)),
        const SizedBox(height: 4),
        Slider(
          value: _sat, min: 0, max: 1,
          activeColor: _current,
          inactiveColor: T.border,
          onChanged: (v) {
            setState(() { _sat = v; _current = _fromHSV(); _hexCtrl.text = _colorToHex(_current); });
            widget.onChanged(_current, _colorToHex(_current));
          },
        ),
        const SizedBox(height: 8),

        // HEX input
        Row(children: [
          // Preview swatch
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _current,
              border: Border.all(color: T.border),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(
            decoration: BoxDecoration(
              color: T.bg2,
              border: Border.all(color: _hexError ? T.red : T.border),
            ),
            child: TextField(
              controller: _hexCtrl,
              style: T.mono(13, color: T.white),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: InputBorder.none,
                hintText: '#FF4655',
                hintStyle: T.mono(13, color: T.greyDim),
              ),
              onSubmitted: _onHexSubmit,
              onChanged: (_) => setState(() => _hexError = false),
            ),
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _onHexSubmit(_hexCtrl.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: T.red,
              child: Text('APPLY', style: T.raj(13)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _HueBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(colors: List.generate(37, (i) =>
        HSVColor.fromAHSV(1, i * 10.0, 1, 1).toColor()));
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
  @override bool shouldRepaint(_) => false;
}
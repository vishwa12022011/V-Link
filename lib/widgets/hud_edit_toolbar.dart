import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'color_picker_sheet.dart';

/// Bottom toolbar shown in HUD edit mode.
/// Contains: Exit | Restore Default | Save  +  Size slider + Opacity slider + Colour picker
class HudEditToolbar extends StatelessWidget {
  final double  btnSize;
  final double  btnOpacity;
  final String  accentHex;
  final void Function(double)  onSizeChanged;
  final void Function(double)  onOpacityChanged;
  final void Function(String)  onAccentChanged;
  final VoidCallback onExit;
  final VoidCallback onRestore;
  final VoidCallback onSave;

  const HudEditToolbar({
    super.key,
    required this.btnSize,
    required this.btnOpacity,
    required this.accentHex,
    required this.onSizeChanged,
    required this.onOpacityChanged,
    required this.onAccentChanged,
    required this.onExit,
    required this.onRestore,
    required this.onSave,
  });

  Color get _accent {
    try { return Color(int.parse('FF${accentHex.replaceAll('#','')}', radix: 16)); }
    catch (_) { return const Color(0xFFFF4655); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xEE0B1117),
        border: const Border(top: BorderSide(color: Color(0xFF1E3045))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // ── Action buttons row ────────────────────────────────────────────
        Row(children: [
          _ActionBtn(label: 'EXIT',    icon: Icons.close,         color: T.grey,  onTap: onExit),
          const SizedBox(width: 8),
          _ActionBtn(label: 'RESTORE', icon: Icons.restore,       color: T.gold,  onTap: onRestore),
          const Spacer(),
          _ActionBtn(label: 'SAVE',    icon: Icons.check_circle,  color: T.red,   onTap: onSave,   filled: true),
        ]),
        const SizedBox(height: 10),

        // ── Sliders ───────────────────────────────────────────────────────
        _SliderRow(
          label: 'SIZE',
          value: ((btnSize - 0.04) / (0.20 - 0.04)).clamp(0.0, 1.0),
          display: '${(btnSize * 100).round()}',
          accentColor: _accent,
          onChanged: (v) => onSizeChanged(0.04 + v * (0.20 - 0.04)),
        ),
        const SizedBox(height: 6),
        _SliderRow(
          label: 'OPACITY',
          value: btnOpacity.clamp(0.0, 1.0),
          display: '${(btnOpacity * 100).round()}%',
          accentColor: _accent,
          onChanged: onOpacityChanged,
        ),
        const SizedBox(height: 10),

        // ── Colour row ────────────────────────────────────────────────────
        Row(children: [
          Text('ACCENT', style: T.mono(9, color: T.grey)),
          const SizedBox(width: 10),
          // Current colour swatch
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quick palette
          ...['#FF4655','#0B3D0B','#082F5D','#854500','#2A002A'].map((hex) {
            final c = Color(int.parse('FF${hex.replaceAll('#','')}', radix: 16));
            final sel = hex.toUpperCase() == accentHex.toUpperCase();
            return GestureDetector(
              onTap: () => onAccentChanged(hex),
              child: Container(
                width: 22, height: 22,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? Colors.white : Colors.transparent, width: 1.5),
                ),
              ),
            );
          }),
          const Spacer(),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: T.bg3, border: Border.all(color: T.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.palette, color: T.grey, size: 13),
                const SizedBox(width: 4),
                Text('MORE', style: T.mono(9, color: T.grey)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ColorPickerSheet(
        initial: _accent,
        onChanged: (_, hex) => onAccentChanged(hex),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color color; final VoidCallback onTap;
  final bool filled;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: Border.all(color: filled ? color : color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: filled ? Colors.white : color),
        const SizedBox(width: 6),
        Text(label, style: T.raj(12, color: filled ? Colors.white : color)),
      ]),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  final String label, display;
  final double value;
  final Color  accentColor;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value,
      required this.display, required this.accentColor, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 60, child: Text(label, style: T.mono(9, color: T.grey))),
    Expanded(child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: accentColor,
        inactiveTrackColor: T.border,
        thumbColor: accentColor,
      ),
      child: Slider(value: value, onChanged: onChanged),
    )),
    SizedBox(width: 40,
        child: Text(display, style: T.mono(9, color: accentColor), textAlign: TextAlign.right)),
  ]);
}

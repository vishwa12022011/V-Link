import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'color_picker_sheet.dart';

/// Compact floating edit panel — sits at top-centre of HUD screen.
/// Small and unobtrusive. Expands downward when a button is selected.
/// Matches the reference Free Fire style: title bar + sliders below.
class HudCompactEditPanel extends StatefulWidget {
  final String?  selectedId;      // null = nothing selected
  final String?  selectedLabel;
  final double   btnSize;
  final double   btnOpacity;
  final double   sensitivity;     // mouse drag sensitivity
  final String   accentHex;
  final void Function(double)  onSizeChanged;
  final void Function(double)  onOpacityChanged;
  final void Function(double)  onSensitivityChanged;
  final void Function(String)  onAccentChanged;
  final VoidCallback onExit;
  final VoidCallback onRestore;
  final VoidCallback onSave;

  const HudCompactEditPanel({
    super.key,
    required this.selectedId,
    required this.selectedLabel,
    required this.btnSize,
    required this.btnOpacity,
    required this.sensitivity,
    required this.accentHex,
    required this.onSizeChanged,
    required this.onOpacityChanged,
    required this.onSensitivityChanged,
    required this.onAccentChanged,
    required this.onExit,
    required this.onRestore,
    required this.onSave,
  });

  @override
  State<HudCompactEditPanel> createState() => _HudCompactEditPanelState();
}

class _HudCompactEditPanelState extends State<HudCompactEditPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _expand;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(HudCompactEditPanel old) {
    super.didUpdateWidget(old);
    // Auto-expand when a button is selected
    if (widget.selectedId != null && !_expanded) {
      _expanded = true;
      _ctrl.forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _accent {
    try { return Color(int.parse('FF${widget.accentHex.replaceAll('#','')}', radix: 16)); }
    catch (_) { return const Color(0xFFFF4655); }
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: const Color(0xEE0B1117),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Top bar: HUD name + action buttons ──────────────────────────
          SizedBox(
            height: 36,
            child: Row(children: [
              // Exit
              _TBtn(icon: Icons.logout, color: T.grey, onTap: widget.onExit),
              // Restore
              _TBtn(icon: Icons.restore, color: T.gold, onTap: widget.onRestore),
              // Title / selected button name
              Expanded(child: GestureDetector(
                onTap: _toggleExpand,
                child: Container(
                  color: const Color(0x22FFFFFF),
                  child: Center(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.selectedId != null
                            ? widget.selectedLabel ?? 'BUTTON'
                            : 'HUD 1',
                        style: T.raj(13, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                          color: T.grey, size: 14),
                    ],
                  )),
                ),
              )),
              // Save
              _TBtn(icon: Icons.save, color: _accent, onTap: widget.onSave, filled: true),
            ]),
          ),

          // ── Expandable sliders section ────────────────────────────────
          SizeTransition(
            sizeFactor: _expand,
            axisAlignment: -1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hint if nothing selected
                  if (widget.selectedId == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Tap any button to select it',
                        style: T.mono(9, color: T.greyDim),
                      ),
                    ),

                  // Size slider (only when button selected)
                  if (widget.selectedId != null)
                    _SliderRow(
                      label: 'SIZE',
                      value: ((widget.btnSize - 0.04) / 0.16).clamp(0.0, 1.0),
                      display: '${(widget.btnSize * 100).round()}',
                      accent: _accent,
                      onChanged: (v) => widget.onSizeChanged(0.04 + v * 0.16),
                    ),

                  // Opacity slider (only when button selected)
                  if (widget.selectedId != null)
                    _SliderRow(
                      label: 'OPACITY',
                      value: widget.btnOpacity.clamp(0.0, 1.0),
                      display: '${(widget.btnOpacity * 100).round()}%',
                      accent: _accent,
                      onChanged: widget.onOpacityChanged,
                    ),

                  // Sensitivity slider (always shown)
                  _SliderRow(
                    label: 'SENS',
                    value: ((widget.sensitivity - 0.5) / 9.5).clamp(0.0, 1.0),
                    display: '${widget.sensitivity.toStringAsFixed(1)}×',
                    accent: _accent,
                    onChanged: (v) => widget.onSensitivityChanged(0.5 + v * 9.5),
                  ),

                  const SizedBox(height: 4),

                  // Accent colour row
                  Row(children: [
                    Text('ACCENT', style: T.mono(8, color: T.grey)),
                    const SizedBox(width: 8),
                    // Quick palette
                    ...['#FF4655','#00E6C3','#FFD700','#FFFFFF','#4CAF50']
                        .map((hex) {
                      final c   = Color(int.parse('FF${hex.replaceAll('#','')}', radix: 16));
                      final sel = hex.toUpperCase() == widget.accentHex.toUpperCase();
                      return GestureDetector(
                        onTap: () => widget.onAccentChanged(hex),
                        child: Container(
                          width: 18, height: 18,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: c, shape: BoxShape.circle,
                            border: Border.all(
                                color: sel ? Colors.white : Colors.transparent,
                                width: 1.5),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showColorPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: T.bg3, border: Border.all(color: T.border)),
                        child: Text('MORE', style: T.mono(8, color: T.grey)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ColorPickerSheet(
        initial: _accent,
        onChanged: (_, hex) => widget.onAccentChanged(hex),
      ),
    );
  }
}

// ── Toolbar icon button ───────────────────────────────────────────────────────
class _TBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final VoidCallback onTap; final bool filled;
  const _TBtn({required this.icon, required this.color,
      required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 36,
      color: filled ? color.withOpacity(0.85) : Colors.transparent,
      child: Icon(icon,
          size: 16,
          color: filled ? Colors.white : color),
    ),
  );
}

// ── Compact slider row ────────────────────────────────────────────────────────
class _SliderRow extends StatelessWidget {
  final String label, display;
  final double value;
  final Color  accent;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value,
      required this.display, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 44, child: Text(label,
          style: T.mono(8, color: T.grey))),
      Expanded(child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: accent,
          inactiveTrackColor: T.border,
          thumbColor: accent,
        ),
        child: Slider(value: value, onChanged: onChanged),
      )),
      SizedBox(width: 36, child: Text(display,
          style: T.mono(8, color: accent),
          textAlign: TextAlign.right)),
    ]),
  );
}

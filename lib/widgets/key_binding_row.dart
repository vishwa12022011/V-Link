import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';

class KeyBindingRow extends StatelessWidget {
  final KeyBinding binding;
  final Future<void> Function(KeyBinding) onUpdate;

  const KeyBindingRow({super.key, required this.binding, required this.onUpdate});

  static bool _isHighlighted(String id) =>
      {'sprint', 'fire', 'ability1'}.contains(id);

  String _short(String s) {
    const m = {'L-SHIFT':'SHIFT','L-CTRL':'CTRL','Mouse_L':'M1','Mouse_R':'M2','SPACE':'SPC'};
    return m[s] ?? (s.length > 5 ? s.substring(0, 5) : s);
  }

  static IconData _ico(String icon) {
    const map = <String, IconData>{
      'joystick': Icons.games, 'sprint': Icons.speed,
      'jump': Icons.keyboard_arrow_up, 'crouch': Icons.keyboard_arrow_down,
      'ability1': Icons.flash_on, 'ability2': Icons.track_changes,
      'ultimate': Icons.star, 'fire': Icons.gps_fixed,
      'scope': Icons.search, 'reload': Icons.refresh,
      'interact': Icons.pan_tool, 'shop': Icons.store,
      'gunswitch': Icons.swap_horiz, 'knife': Icons.edit,
      'grenade': Icons.sports_baseball, 'emoji': Icons.emoji_emotions,
      'mappin': Icons.location_on, 'mic': Icons.mic,
      'speaker': Icons.volume_up, 'settings': Icons.settings,
      'chat': Icons.chat_bubble_outline, 'scoreboard': Icons.leaderboard,
    };
    return map[icon] ?? Icons.crop_square;
  }

  @override
  Widget build(BuildContext context) {
    final hi = _isHighlighted(binding.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: T.bg1,
        border: Border.all(color: hi ? T.red : T.border, width: hi ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRemap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              // Icon box
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: hi ? T.red.withOpacity(0.15) : T.bg3,
                  border: Border.all(color: hi ? T.red : T.border),
                ),
                child: Icon(_ico(binding.icon),
                    color: hi ? T.red : T.grey, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(binding.label, style: T.raj(15)),
                  const SizedBox(height: 2),
                  Text('Sequence: ${binding.keySequence}',
                      style: T.mono(9, color: T.greyDim)),
                ],
              )),
              // Key chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hi ? T.red : T.bg3,
                  border: Border.all(color: hi ? T.red : T.border),
                ),
                child: Text(_short(binding.keySequence),
                    style: T.raj(14,
                        color: hi ? Colors.white : T.white)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showRemap(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: T.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _RemapSheet(
        binding: binding,
        onSave: (seq) => onUpdate(binding.copyWith(keySequence: seq)),
      ),
    );
  }
}

// ── Remap bottom sheet ────────────────────────────────────────────────────────
class _RemapSheet extends StatefulWidget {
  final KeyBinding binding;
  final void Function(String) onSave;
  const _RemapSheet({required this.binding, required this.onSave});

  @override
  State<_RemapSheet> createState() => _RemapSheetState();
}

class _RemapSheetState extends State<_RemapSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.binding.keySequence); }
  @override
  void dispose()   { _ctrl.dispose(); super.dispose(); }

  static const _presets = [
    'W','A','S','D','SPACE','L-SHIFT','L-CTRL',
    'E','Q','X','R','F','B','V','T','M',
    'Mouse_L','Mouse_R','TAB','ESC','ENTER',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('REMAP  ${widget.binding.label.toUpperCase()}', style: T.orb(16)),
          const SizedBox(height: 4),
          Text('Tap a preset or type a custom sequence', style: T.mono(10, color: T.grey)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8,
            children: _presets.map((k) => GestureDetector(
              onTap: () => setState(() => _ctrl.text = k),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
                child: Text(k, style: T.mono(10, color: T.white)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.red)),
            child: TextField(
              controller: _ctrl,
              style: T.raj(15),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: 'Custom (e.g. CTRL+W)…',
                hintStyle: T.mono(10, color: T.greyDim),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () { widget.onSave(_ctrl.text.trim()); Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: T.red,
                child: Center(child: Text('APPLY', style: T.raj(14))),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(color: T.bg3, border: Border.all(color: T.border)),
                child: Text('CANCEL', style: T.raj(13, color: T.grey)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

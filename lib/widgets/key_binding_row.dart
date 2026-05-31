import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart'; // Added missing package import
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import 'qwerty_key_picker.dart';

class KeyBindingRow extends StatelessWidget {
  final KeyBinding binding;
  final Future<void> Function(KeyBinding) onUpdate;

  const KeyBindingRow({
    super.key,
    required this.binding,
    required this.onUpdate,
  });

  static bool _isHighlighted(String id) =>
      {'sprint', 'fire', 'ability1', 'ads'}.contains(id);

  static IconData _ico(String icon) {
    const m = <String, IconData>{
      'joystick': Icons.games,
      'sprint': Icons.speed,
      'jump': Icons.keyboard_arrow_up,
      'crouch': Icons.keyboard_arrow_down,
      'ability1': Icons.flash_on,
      'ability2': Icons.track_changes,
      'ultimate': Icons.star,
      'fire': Icons.gps_fixed,
      'scope': Icons.search,
      'reload': Icons.refresh,
      'interact': Icons.sports_mma,
      'shop': Icons.store,
      'gunswitch': Icons.swap_horiz,
      'knife': Icons.edit,
      'grenade': Icons.radio_button_checked,
      'emoji': Icons.emoji_emotions,
      'mappin': Icons.location_on,
      'mic': Icons.mic,
      'speaker': Icons.volume_up,
      'settings': Icons.settings,
      'chat': Icons.chat_bubble_outline,
      'scoreboard': Icons.leaderboard,
    };
    return m[icon] ?? Icons.crop_square;
  }

  @override
  Widget build(BuildContext context) {
    final hi = _isHighlighted(binding.id);
    final keys = binding.keySequence.split('+');

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hi
                      ? T.red.withValues(alpha: 0.15)
                      : T.bg3, // Updated deprecation
                  border: Border.all(color: hi ? T.red : T.border),
                ),
                child: Icon(_ico(binding.icon),
                    color: hi ? T.red : T.grey, size: 18),
              ),
              const SizedBox(width: 14),
              // Labels
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(binding.label, style: T.raj(15)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('Sequence: ', style: T.mono(9, color: T.greyDim)),
                    // Show each key as a small chip
                    ...keys.asMap().entries.map((e) =>
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          if (e.key > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text('+',
                                  style: T.mono(10, color: T.greyDim)),
                            ),
                          Container(
                            margin: const EdgeInsets.only(right: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: T.bg3,
                              border: Border.all(color: T.border),
                            ),
                            child:
                                Text(e.value, style: T.mono(8, color: T.teal)),
                          ),
                        ])),
                    if (binding.isHold)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        color: T.red,
                        child:
                            Text('HOLD', style: T.mono(7, color: Colors.white)),
                      ),
                  ]),
                ],
              )),
              // Key chip(s)
              _KeyChips(keys: keys, isHold: binding.isHold, accent: hi),
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
        onSave: (newSeq, isHold, isToggle) => onUpdate(
          binding.copyWith(
            keySequence: newSeq,
            isHold: isHold,
            isToggle: isToggle || isHold,
          ),
        ),
      ),
    );
  }
}

// ── Key chips display ─────────────────────────────────────────────────────────
class _KeyChips extends StatelessWidget {
  final List<String> keys;
  final bool isHold, accent;
  const _KeyChips(
      {required this.keys, required this.isHold, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...keys
          .asMap()
          .entries
          .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                if (e.key > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text('+', style: T.mono(10, color: T.greyDim)),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent ? T.red : T.bg3,
                    border: Border.all(color: accent ? T.red : T.border),
                  ),
                  child: Text(
                    e.value.length > 6 ? e.value.substring(0, 6) : e.value,
                    style: T.raj(13, color: accent ? Colors.white : T.white),
                  ),
                ),
              ])),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REMAP BOTTOM SHEET  —  full QWERTY + combo builder + hold toggle
// ══════════════════════════════════════════════════════════════════════════════
class _RemapSheet extends StatefulWidget {
  final KeyBinding binding;
  final void Function(String seq, bool isHold, bool isToggle) onSave;

  const _RemapSheet({required this.binding, required this.onSave});

  @override
  State<_RemapSheet> createState() => _RemapSheetState();
}

class _RemapSheetState extends State<_RemapSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late List<String> _combo; // list of selected keys in combo
  late bool _isHold;
  late bool _isToggle;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _combo = widget.binding.keySequence.split('+');
    _isHold = widget.binding.isHold;
    _isToggle = widget.binding.isToggle;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _comboStr => _combo.join('+');

  void _addKey(String k) {
    if (!_combo.contains(k)) setState(() => _combo.add(k));
  }

  void _removeKey(String k) {
    if (_combo.length > 1) setState(() => _combo.remove(k));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => Container(
              color: T.bg1,
              child: Column(
                children: [
                  // Handle
                  Center(
                      child: Container(
                          width: 40,
                          height: 3,
                          color: T.border,
                          margin: const EdgeInsets.symmetric(vertical: 10))),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('REMAP: ${widget.binding.label.toUpperCase()}',
                                style: T.orb(14)),
                            const SizedBox(height: 2),
                            Text('Build a key sequence or combo',
                                style: T.mono(9, color: T.grey)),
                          ])),
                      WidgetKeybindingRowSaveButton(
                        onTap: () {
                          _onSave();
                          Navigator.pop(context);
                        },
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Current combo display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: T.bg2, border: Border.all(color: T.red)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CURRENT COMBO',
                                style: T.mono(8, color: T.grey)),
                            const SizedBox(height: 8),
                            ReorderableWrap(
                              spacing: 6,
                              runSpacing: 6,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  final item = _combo.removeAt(oldIndex);
                                  _combo.insert(newIndex, item);
                                });
                              },
                              children: _combo
                                  .asMap()
                                  .entries
                                  .map((e) => Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (e.key > 0)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: Text('+',
                                                    style: T.mono(10,
                                                        color: T.greyDim)),
                                              ),
                                            GestureDetector(
                                              onTap: () => _removeKey(e.value),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: T.red.withValues(
                                                      alpha:
                                                          0.2), // Updated deprecation fixed here
                                                  border:
                                                      Border.all(color: T.red),
                                                ),
                                                child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(e.value,
                                                          style: T.mono(11,
                                                              color: T.white)),
                                                      const SizedBox(width: 5),
                                                      const Icon(Icons.close,
                                                          size: 11,
                                                          color: T.grey),
                                                    ]),
                                              ),
                                            ),
                                          ]))
                                  .toList(),
                            ),
                            if (_combo.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Tap a key chip above to remove it',
                                    style: T.mono(8, color: T.greyDim)),
                              ),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        color: T.bg3, border: Border.all(color: T.border)),
                    child: TabBar(
                      controller: _tab,
                      labelColor: T.red,
                      unselectedLabelColor: T.grey,
                      indicatorColor: T.red,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: T.raj(13),
                      tabs: const [
                        Tab(text: 'KEYBOARD'),
                        Tab(text: 'OPTIONS'),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                      child: TabBarView(
                    controller: _tab,
                    children: [
                      // ── KEYBOARD TAB ───────────────────────────────────────────
                      SingleChildScrollView(
                        controller: scroll,
                        padding: const EdgeInsets.all(16),
                        child: QwertyKeyPicker(
                          currentKey: _combo.last,
                          currentIsHold: _isHold,
                          onSelect: (k, hold) {
                            _addKey(k);
                            setState(() => _isHold = hold);
                          },
                        ),
                      ),

                      // ── OPTIONS TAB ────────────────────────────────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BUTTON BEHAVIOUR',
                                  style: T.mono(9, color: T.grey)),
                              const SizedBox(height: 12),

                              // Hold toggle
                              _OptionTile(
                                icon: Icons.lock_outline,
                                label: 'Hold Mode',
                                sub:
                                    'Holds all combo keys while toggled ON. Release on second tap.',
                                value: _isHold,
                                onChanged: (v) => setState(() {
                                  _isHold = v;
                                  if (v) _isToggle = true;
                                }),
                              ),
                              const SizedBox(height: 8),

                              // Toggle
                              _OptionTile(
                                icon: Icons.toggle_on_outlined,
                                label: 'Toggle Mode',
                                sub:
                                    'First tap activates, second tap deactivates (fires key once each time).',
                                value: _isToggle,
                                onChanged: (v) => setState(() => _isToggle = v),
                              ),
                              const SizedBox(height: 20),

                              // Quick clear
                              GestureDetector(
                                onTap: () => setState(() => _combo = ['SPACE']),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                      color: T.bg3,
                                      border: Border.all(color: T.border)),
                                  child: Center(
                                      child: Text('CLEAR COMBO',
                                          style: T.raj(13, color: T.grey))),
                                ),
                              ),
                            ]),
                      ),
                    ],
                  )),
                ],
              ),
            ));
  }

  void _onSave() => widget.onSave(_comboStr, _isHold, _isToggle);
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _OptionTile(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? T.red.withValues(alpha: 0.08)
              : T.bg3, // Updated deprecation
          border: Border.all(color: value ? T.red : T.border),
        ),
        child: Row(children: [
          Icon(icon, color: value ? T.red : T.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: T.raj(14, color: value ? T.red : T.white)),
                const SizedBox(height: 2),
                Text(sub, style: T.mono(9, color: T.greyDim)),
              ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: T.red, // Fixed deprecation warning cleanly here
            inactiveTrackColor: T.bg0,
            thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) return T.red;
              return T.greyDim;
            }),
          ),
        ]),
      );
}

class WidgetKeybindingRowSaveButton extends StatelessWidget {
  const WidgetKeybindingRowSaveButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: T.red,
        child: Text('SAVE', style: T.raj(14)),
      ),
    );
  }
}

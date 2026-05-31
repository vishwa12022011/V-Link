import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Full QWERTY keyboard grid for the bindings remap screen.
class QwertyKeyPicker extends StatefulWidget {
  final String currentKey;
  final bool currentIsHold;
  final void Function(String key, bool isHold) onSelect;

  const QwertyKeyPicker({
    super.key,
    required this.currentKey,
    required this.currentIsHold,
    required this.onSelect,
  });

  @override
  State<QwertyKeyPicker> createState() => _QwertyKeyPickerState();
}

class _QwertyKeyPickerState extends State<QwertyKeyPicker> {
  late String _sel;
  late bool _hold;

  @override
  void initState() {
    super.initState();
    _sel = widget.currentKey;
    _hold = widget.currentIsHold;
  }

  static const _rows = [
    ['F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12'],
    ['1','2','3','4','5','6','7','8','9','0','-','='],
    ['Q','W','E','R','T','Y','U','I','O','P','[',']'],
    ['A','S','D','F','G','H','J','K','L',';',"'"],
    ['Z','X','C','V','B','N','M',',','.','/'],
    ['L-SHIFT','R-SHIFT','L-CTRL','R-CTRL','L-ALT','R-ALT',
     'SPACE','TAB','CAPS','ENTER','BACKSPACE','ESC'],
    ['Mouse_L','Mouse_R','Mouse_M'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hold toggle
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            // FIXED: Replaced withOpacity with withValues(alpha: ...)
            color: _hold ? T.red.withValues(alpha: 0.15) : T.bg3,
            border: Border.all(color: _hold ? T.red : T.border),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline, color: T.grey, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HOLD MODE', style: T.raj(14, color: _hold ? T.red : T.white)),
              Text('Button stays active while toggled ON',
                  style: T.mono(9, color: T.greyDim)),
            ])),
            Switch(
              value: _hold,
              onChanged: (v) {
                setState(() => _hold = v);
                widget.onSelect(_sel, _hold);
              },
              // FIXED: Replaced activeColor with track/thumb colors using WidgetStateProperty
              trackColor: WidgetStateProperty.resolveWith((states) => 
                states.contains(WidgetState.selected) ? T.red : T.bg0),
              thumbColor: WidgetStateProperty.resolveWith((states) => 
                states.contains(WidgetState.selected) ? Colors.white : T.greyDim),
            ),
          ]),
        ),

        // Current selection display
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.red)),
          child: Row(children: [
            Text('SELECTED:', style: T.mono(9, color: T.grey)),
            const SizedBox(width: 10),
            Text(_sel, style: T.raj(16, color: T.red)),
            if (_hold) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: T.red,
                  child: Text('HOLD', style: T.mono(8, color: Colors.white))),
            ],
          ]),
        ),

        // Key grid rows
        ..._rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(spacing: 5, runSpacing: 5,
            children: row.map((k) {
              final sel = k == _sel;
              final wide = k.length > 3;
              return GestureDetector(
                onTap: () {
                  setState(() => _sel = k);
                  widget.onSelect(k, _hold);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.symmetric(
                      horizontal: wide ? 10 : 8, vertical: 7),
                  constraints: BoxConstraints(minWidth: wide ? 72 : 34),
                  decoration: BoxDecoration(
                    color: sel ? T.red : T.bg3,
                    border: Border.all(color: sel ? T.red : T.border),
                  ),
                  child: Center(child: Text(k,
                      style: T.mono(10, color: sel ? Colors.white : T.white))),
                ),
              );
            }).toList(),
          ),
        )),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/profile_service.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../services/hid_service.dart';
import '../utils/app_theme.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/hud_circle_btn.dart';
import '../widgets/weapon_slot_bar.dart';
import '../widgets/hud_compact_edit_panel.dart';

class ControllerScreen extends StatefulWidget {
  final HudProfile profile;
  const ControllerScreen({super.key, required this.profile});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  // Edit state
  bool _editMode = false;
  String? _selectedId;
  double _editSize = 0.085;
  double _editOpacity = 0.85;

  // Working button copies
  late List<HudBtn> _buttons;
  late List<HudBtn> _defaults;

  // Profile live values
  late String _accentHex;
  late double _sensitivity;

  // Toggle states
  final Map<String, bool> _toggleStates = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _buttons = widget.profile.buttons.map((b) => b.clone()).toList();
    _defaults = widget.profile.buttons.map((b) => b.clone()).toList();
    _accentHex = widget.profile.accentHex;
    _sensitivity = widget.profile.sensitivityScale;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsm = context.read<WeaponSlotModel>();
      wsm.syncFromBindings(widget.profile.bindings);
      wsm.setAccent(_accent);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Color get _accent {
    try {
      return Color(int.parse('FF${_accentHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFFF4655);
    }
  }

  // ── Key sending — routes to active transport ───────────────────────────────
  void _sendKey(String key, bool pressed) {
    if (_editMode) return;
    final conn = context.read<ConnModel>();
    final hid = context.read<HidService>();

    // Priority: BT HID → USB HID → BLE → WiFi UDP
    if (hid.btHidActive || hid.usbHidActive) {
      hid.sendKey(key, pressed: pressed);
    } else if (conn.mode == Transport.ble) {
      context.read<BleService>().sendKey(key, pressed: pressed);
    } else {
      context.read<WifiService>().sendKey(key, pressed: pressed);
    }
  }

  void _sendTap(String key) {
    _sendKey(key, true);
    Future.delayed(
        const Duration(milliseconds: 80), () => _sendKey(key, false));
  }

  void _sendMouse(int dx, int dy) {
    if (_editMode) return;
    final hid = context.read<HidService>();
    final conn = context.read<ConnModel>();
    if (hid.btHidActive || hid.usbHidActive) {
      hid.sendMouse(dx, dy);
    } else if (conn.mode == Transport.ble) {
      context.read<BleService>().sendMouse(dx, dy);
    } else {
      context.read<WifiService>().sendMouse(dx, dy);
    }
  }

  // ── Toggle ─────────────────────────────────────────────────────────────────
  void _handleToggle(String bindId, String keySeq, bool isHold) {
    final nowOn = !(_toggleStates[bindId] ?? false);
    setState(() => _toggleStates[bindId] = nowOn);
    if (isHold) {
      _sendKey(keySeq, nowOn);
    } else {
      _sendTap(keySeq);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  KeyBinding _binding(String bindId) => widget.profile.bindings.firstWhere(
        (b) => b.id == bindId,
        orElse: () => KeyBinding(
            id: bindId, label: bindId, keySequence: bindId, icon: bindId),
      );

  HudBtn? _btn(String id) {
    try {
      return _buttons.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  void _selectBtn(String id) {
    if (!_editMode) return;
    final b = _btn(id);
    if (b == null) return;
    setState(() {
      _selectedId = id;
      _editSize = b.size;
      _editOpacity = b.opacity;
    });
  }

  void _updateSelected({double? size, double? opacity}) {
    if (_selectedId == null) return;
    setState(() {
      final i = _buttons.indexWhere((b) => b.id == _selectedId);
      if (i < 0) return;
      if (size != null) _buttons[i].size = size;
      if (opacity != null) _buttons[i].opacity = opacity;
      _editSize = _buttons[i].size;
      _editOpacity = _buttons[i].opacity;
    });
  }

  void _saveEdit() {
    final ps = context.read<ProfileService>();
    widget.profile.buttons
      ..clear()
      ..addAll(_buttons.map((b) => b.clone()));
    widget.profile.accentHex = _accentHex;
    widget.profile.sensitivityScale = _sensitivity;
    context.read<WeaponSlotModel>().setAccent(_accent);
    ps.save(widget.profile);
    setState(() {
      _editMode = false;
      _selectedId = null;
    });
  }

  void _restoreDefaults() => setState(() {
        _buttons = _defaults.map((b) => b.clone()).toList();
        _selectedId = null;
      });

  String? _selectedLabel() {
    if (_selectedId == null) return null;
    final b = _btn(_selectedId!);
    return b != null ? _binding(b.bindId).label : null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final wsm = context.watch<WeaponSlotModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, box) {
        final W = box.maxWidth;
        final H = box.maxHeight;

        return Stack(clipBehavior: Clip.none, children: [
          // 1. Dot-grid background
          Positioned.fill(child: _HudBg()),

          // 2. Finger drag → mouse move
          if (!_editMode)
            Positioned.fill(
                child: _MouseDragLayer(
              sensitivity: _sensitivity,
              onDelta: _sendMouse,
            )),

          // 3. Ring crosshair
          Center(child: _RingCrosshair(accentColor: _accent)),

          // 4. Weapon slot bar (bottom centre-left)
          Positioned(
            bottom: 6,
            left: W * 0.28,
            child: WeaponSlotBar(
              model: wsm,
              editMode: _editMode,
              onKeyTap: (key) => _sendTap(key),
            ),
          ),

          // 5. Draggable joystick
          _DraggableJoystick(
            W: W,
            H: H,
            editMode: _editMode,
            onKey: (k, p) => _sendKey(k, p),
          ),

          // 6. All HUD buttons
          ..._buildAllButtons(ctx, W, H),

          // 7. Edit outlines
          if (_editMode) ..._buildEditOutlines(W, H),

          // 8. Compact edit panel (top-centre)
          if (_editMode)
            Positioned(
              top: 0,
              left: W / 2 - 160,
              child: HudCompactEditPanel(
                selectedId: _selectedId,
                selectedLabel: _selectedLabel(),
                btnSize: _editSize,
                btnOpacity: _editOpacity,
                sensitivity: _sensitivity,
                accentHex: _accentHex,
                onSizeChanged: (v) => _updateSelected(size: v),
                onOpacityChanged: (v) => _updateSelected(opacity: v),
                onSensitivityChanged: (v) => setState(() => _sensitivity = v),
                onAccentChanged: (hex) {
                  setState(() => _accentHex = hex);
                  wsm.setAccent(_accent);
                },
                onExit: () => setState(() {
                  _editMode = false;
                  _selectedId = null;
                }),
                onRestore: _restoreDefaults,
                onSave: _saveEdit,
              ),
            ),

          // 9. EDIT button (play mode)
          if (!_editMode)
            Positioned(
              top: 4,
              left: W / 2 - 34,
              child: GestureDetector(
                onTap: () => setState(() {
                  _editMode = true;
                  _selectedId = null;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xBB0B1117),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.edit, color: Color(0xAAFFFFFF), size: 12),
                    const SizedBox(width: 5),
                    Text('EDIT',
                        style: T.mono(9, color: const Color(0xAAFFFFFF))),
                  ]),
                ),
              ),
            ),

          // 10. Back button
          Positioned(
            top: 4,
            left: 6,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xBB0B1117),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_new, color: T.grey, size: 10),
                  const SizedBox(width: 3),
                  Text('EXIT', style: T.mono(8, color: T.grey)),
                ]),
              ),
            ),
          ),

          // 11. Connection status
          Positioned(top: 4, right: 6, child: _ConnDot(accent: _accent)),
        ]);
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD ALL HUD BUTTONS
  // ══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllButtons(BuildContext ctx, double W, double H) {
    final widgets = <Widget>[];

    for (final btn in _buttons) {
      if (!btn.visible) continue;
      final bind = _binding(btn.bindId);
      final sz = _sz(W, btn.size);

      final isFire = btn.bindId == 'fire' || btn.bindId == 'fire_left';
      final isToggle = bind.isToggle || bind.isHold;
      final isMute = btn.bindId == 'mic' || btn.bindId == 'speaker';

      final child = HudCircleBtn(
        size: sz,
        iconKey: bind.icon,
        keySeq: bind.keySequence,
        bindId: btn.bindId,
        editMode: _editMode,
        isFireBtn: isFire && !isToggle,
        isToggleBtn: isToggle,
        isToggleOn: _toggleStates[btn.bindId] ?? false,
        isMuteStyle: isMute,
        accentColor: _accent,
        onPress: () => _sendKey(bind.keySequence, true),
        onRelease: () => _sendKey(bind.keySequence, false),
        onToggle: () =>
            _handleToggle(btn.bindId, bind.keySequence, bind.isHold),
      );

      widgets.add(_DraggableBtn(
        key: ValueKey(btn.id),
        btn: btn,
        sz: sz,
        W: W,
        H: H,
        editMode: _editMode,
        opacity: btn.opacity,
        onTap: () => _selectBtn(btn.id),
        onDragEnd: (nx, ny) => setState(() {
          btn.x = nx;
          btn.y = ny;
        }),
        child: child,
      ));
    }

    return widgets;
  }

  List<Widget> _buildEditOutlines(double W, double H) => _buttons.map((btn) {
        final sz = _sz(W, btn.size);
        return Positioned(
          left: W * btn.x - sz / 2 - 3,
          top: H * btn.y - sz / 2 - 3,
          child: IgnorePointer(
              child: Container(
            width: sz + 6,
            height: sz + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedId == btn.id
                    ? const Color(0xFF00E6C3)
                    : const Color(0x44FFFFFF),
                width: _selectedId == btn.id ? 1.5 : 0.8,
              ),
            ),
          )),
        );
      }).toList();

  double _sz(double W, double frac) => (W * frac).clamp(28.0, 130.0);
}

// ══════════════════════════════════════════════════════════════════════════════
// DRAGGABLE BUTTON WRAPPER
// ══════════════════════════════════════════════════════════════════════════════
class _DraggableBtn extends StatelessWidget {
  final HudBtn btn;
  final double sz, W, H, opacity;
  final bool editMode;
  final Widget child;
  final VoidCallback onTap;
  final void Function(double, double) onDragEnd;

  const _DraggableBtn({
    super.key,
    required this.btn,
    required this.sz,
    required this.W,
    required this.H,
    required this.editMode,
    required this.opacity,
    required this.child,
    required this.onTap,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        left: W * btn.x - sz / 2,
        top: H * btn.y - sz / 2,
        child: GestureDetector(
          onTap: editMode ? onTap : null,
          onPanUpdate: editMode
              ? (d) {
                  final nx = (btn.x + d.delta.dx / W).clamp(0.01, 0.99);
                  final ny = (btn.y + d.delta.dy / H).clamp(0.01, 0.99);
                  onDragEnd(nx, ny);
                }
              : null,
          child: Opacity(opacity: opacity, child: child),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// DRAGGABLE JOYSTICK
// ══════════════════════════════════════════════════════════════════════════════
class _DraggableJoystick extends StatefulWidget {
  final double W, H;
  final bool editMode;
  final void Function(String, bool) onKey;
  const _DraggableJoystick(
      {required this.W,
      required this.H,
      required this.editMode,
      required this.onKey});

  @override
  State<_DraggableJoystick> createState() => _DraggableJoystickState();
}

class _DraggableJoystickState extends State<_DraggableJoystick> {
  double _fx = 0.12, _fy = 0.65;

  @override
  Widget build(BuildContext context) {
    final sz = (widget.W * 0.175).clamp(80.0, 160.0);
    return Positioned(
      left: widget.W * _fx - sz / 2,
      top: widget.H * _fy - sz / 2,
      child: GestureDetector(
        onPanUpdate: widget.editMode
            ? (d) => setState(() {
                  _fx = (_fx + d.delta.dx / widget.W).clamp(0.02, 0.45);
                  _fy = (_fy + d.delta.dy / widget.H).clamp(0.30, 0.95);
                })
            : null,
        child: JoystickWidget(
          size: sz,
          editMode: widget.editMode,
          onKey: widget.onKey,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOUSE DRAG LAYER
// ══════════════════════════════════════════════════════════════════════════════
class _MouseDragLayer extends StatefulWidget {
  final double sensitivity;
  final void Function(int dx, int dy) onDelta;
  const _MouseDragLayer({required this.sensitivity, required this.onDelta});

  @override
  State<_MouseDragLayer> createState() => _MouseDragLayerState();
}

class _MouseDragLayerState extends State<_MouseDragLayer> {
  double _remX = 0, _remY = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (d) {
          _remX += d.delta.dx * widget.sensitivity;
          _remY += d.delta.dy * widget.sensitivity;
          final ix = _remX.truncate();
          final iy = _remY.truncate();
          if (ix != 0 || iy != 0) {
            _remX -= ix;
            _remY -= iy;
            widget.onDelta(ix, iy);
          }
        },
        onPanEnd: (_) {
          _remX = 0;
          _remY = 0;
        },
        child: const SizedBox.expand(),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// RING CROSSHAIR
// ══════════════════════════════════════════════════════════════════════════════
class _RingCrosshair extends StatelessWidget {
  final Color accentColor;
  const _RingCrosshair({required this.accentColor});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(46, 46), painter: _RingCrosshairP(accentColor));
}

class _RingCrosshairP extends CustomPainter {
  final Color accent;
  const _RingCrosshairP(this.accent);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 3;
    const gap = 0.20;
    const pi = 3.14159265;

    canvas.drawCircle(
        c,
        r + 2,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(rect, i * (pi / 2) + gap, pi / 2 - gap * 2, false, rp);
    }
    canvas.drawCircle(c, 2.5, Paint()..color = Colors.white.withOpacity(0.92));
    canvas.drawCircle(
        c,
        r * 0.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withOpacity(0.14)
          ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_RingCrosshairP o) => o.accent != accent;
}

// ══════════════════════════════════════════════════════════════════════════════
// HUD BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
class _HudBg extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => CustomPaint(painter: _HudBgP());
}

class _HudBgP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFF1A2330).withOpacity(0.16);
    for (double x = 0; x < s.width; x += 40)
      for (double y = 0; y < s.height; y += 40)
        canvas.drawCircle(Offset(x, y), 0.6, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// CONNECTION DOT
// ══════════════════════════════════════════════════════════════════════════════
class _ConnDot extends StatelessWidget {
  final Color accent;
  const _ConnDot({required this.accent});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();
    final hid = context.watch<HidService>();
    final active = conn.isConnected || hid.btHidActive || hid.usbHidActive;
    final label = hid.btHidActive
        ? 'BT HID'
        : hid.usbHidActive
            ? 'USB HID'
            : conn.isConnected
                ? (conn.deviceName ?? 'LINKED')
                : 'NO LINK';
    final color = active ? const Color(0xFF00E6C3) : const Color(0xFF3D5166);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xBB0B1117),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: T.mono(8, color: color)),
      ]),
    );
  }
}

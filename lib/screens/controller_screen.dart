import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/profile_service.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../utils/app_theme.dart';
import '../widgets/joystick_widget.dart';
import '../widgets/hud_circle_btn.dart';
import '../widgets/weapon_slot_bar.dart';
import '../widgets/hud_edit_toolbar.dart';

class ControllerScreen extends StatefulWidget {
  final HudProfile profile;
  const ControllerScreen({super.key, required this.profile});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool    _editMode   = false;
  String? _selectedId;
  double  _editSize    = 0.085;
  double  _editOpacity = 0.85;

  late List<HudBtn> _buttons;
  late List<HudBtn> _defaultButtons;
  late String       _accentHex;

  final Map<String, bool> _toggleStates = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _buttons        = widget.profile.buttons.map((b) => b.clone()).toList();
    _defaultButtons = widget.profile.buttons.map((b) => b.clone()).toList();
    _accentHex      = widget.profile.accentHex;

    // Sync weapon slot keys from profile bindings
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
      return Color(int.parse(
          'FF${_accentHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFFF4655);
    }
  }

  // ── Key sending ────────────────────────────────────────────────────────────
  void _sendKey(String key, bool pressed) {
    if (_editMode) return;
    final conn = context.read<ConnModel>();
    if (conn.mode == Transport.ble) {
      context.read<BleService>().sendKey(key, pressed: pressed);
    } else {
      context.read<WifiService>().sendKey(key, pressed: pressed);
    }
  }

  // Single fire (press + release)
  void _sendTap(String key) {
    _sendKey(key, true);
    Future.delayed(const Duration(milliseconds: 80),
        () => _sendKey(key, false));
  }

  // ── Toggle logic ───────────────────────────────────────────────────────────
  void _handleToggle(String bindId, String keySeq, bool isHold) {
    final nowOn = !(_toggleStates[bindId] ?? false);
    setState(() => _toggleStates[bindId] = nowOn);
    if (isHold) {
      _sendKey(keySeq, nowOn);
    } else {
      _sendTap(keySeq);
    }
  }

  // ── Lookup helpers ─────────────────────────────────────────────────────────
  KeyBinding _binding(String bindId) => widget.profile.bindings.firstWhere(
        (b) => b.id == bindId,
        orElse: () => KeyBinding(
            id: bindId, label: bindId,
            keySequence: bindId, icon: bindId),
      );

  HudBtn? _btn(String id) {
    try { return _buttons.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  void _selectBtn(String id) {
    if (!_editMode) return;
    final b = _btn(id);
    if (b == null) return;
    setState(() {
      _selectedId  = id;
      _editSize    = b.size;
      _editOpacity = b.opacity;
    });
  }

  void _updateSelected({double? size, double? opacity}) {
    if (_selectedId == null) return;
    setState(() {
      final i = _buttons.indexWhere((b) => b.id == _selectedId);
      if (i < 0) return;
      if (size    != null) _buttons[i].size    = size;
      if (opacity != null) _buttons[i].opacity = opacity;
      _editSize    = _buttons[i].size;
      _editOpacity = _buttons[i].opacity;
    });
  }

  void _saveEdit() {
    final ps = context.read<ProfileService>();
    widget.profile.buttons
      ..clear()
      ..addAll(_buttons.map((b) => b.clone()));
    widget.profile.accentHex = _accentHex;
    context.read<WeaponSlotModel>().setAccent(_accent);
    ps.save(widget.profile);
    setState(() { _editMode = false; _selectedId = null; });
  }

  void _restoreDefaults() {
    setState(() {
      _buttons    = _defaultButtons.map((b) => b.clone()).toList();
      _selectedId = null;
    });
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

          // 1. Dot grid background
          Positioned.fill(child: _HudBg()),

          // 2. Finger-drag → mouse movement
          if (!_editMode)
            Positioned.fill(child: _MouseDragLayer(
              onDelta: (dx, dy) {
                final conn = ctx.read<ConnModel>();
                if (conn.mode == Transport.ble) {
                  ctx.read<BleService>().sendMouse(dx, dy);
                } else {
                  ctx.read<WifiService>().sendMouse(dx, dy);
                }
              },
            )),

          // 3. Ring crosshair (centre)
          Center(child: _RingCrosshair(accentColor: _accent)),

          // 4. Weapon slot bar (bottom-centre)
          Positioned(
            bottom: _editMode ? 90 : 4,
            left:   W * 0.30,
            child:  WeaponSlotBar(
              model:    wsm,
              editMode: _editMode,
              onKeyTap: (key) => _sendTap(key),
            ),
          ),

          // 5. All HUD circle buttons
          ..._buildAllButtons(ctx, W, H),

          // 6. Edit outlines
          if (_editMode) ..._buildEditOutlines(W, H),

          // 7. Edit toolbar
          if (_editMode)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: HudEditToolbar(
                btnSize:          _editSize,
                btnOpacity:       _editOpacity,
                accentHex:        _accentHex,
                onSizeChanged:    (v) => _updateSelected(size: v),
                onOpacityChanged: (v) => _updateSelected(opacity: v),
                onAccentChanged:  (hex) {
                  setState(() => _accentHex = hex);
                  wsm.setAccent(_accent);
                },
                onExit:    () => setState(() { _editMode = false; _selectedId = null; }),
                onRestore: _restoreDefaults,
                onSave:    _saveEdit,
              ),
            ),

          // 8. EDIT button (play mode only)
          if (!_editMode)
            Positioned(
              top: 6, left: W / 2 - 36,
              child: GestureDetector(
                onTap: () => setState(() {
                  _editMode = true; _selectedId = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xBB0B1117),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.edit,
                        color: Color(0xAAFFFFFF), size: 13),
                    const SizedBox(width: 5),
                    Text('EDIT',
                        style: T.mono(9,
                            color: const Color(0xAAFFFFFF))),
                  ]),
                ),
              ),
            ),

          // 9. Edit mode banner
          if (_editMode)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: const Color(0xFF00E6C3).withOpacity(0.10),
                child: Center(child: Text(
                  _selectedId != null
                      ? 'DRAG TO MOVE  ·  USE SLIDERS BELOW'
                      : 'TAP A BUTTON TO SELECT',
                  style: T.mono(9,
                      color: const Color(0xFF00E6C3)),
                )),
              ),
            ),

          // 10. Back button
          Positioned(
            top: 6, left: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xBB0B1117),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_new,
                      color: T.grey, size: 11),
                  const SizedBox(width: 4),
                  Text('EXIT', style: T.mono(8, color: T.grey)),
                ]),
              ),
            ),
          ),

          // 11. Connection dot
          Positioned(
              top: 6, right: 8,
              child: _ConnDot(accent: _accent)),
        ]);
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD ALL HUD BUTTONS
  // ══════════════════════════════════════════════════════════════════════════
  List<Widget> _buildAllButtons(BuildContext ctx, double W, double H) {
    final widgets = <Widget>[];

    // Joystick
    widgets.add(Positioned(
      left: W * 0.07 - _sz(W, 0.175) / 2,
      top:  H * 0.60 - _sz(W, 0.175) / 2,
      child: JoystickWidget(
        size:     _sz(W, 0.175),
        editMode: _editMode,
        onKey:    (k, p) => _sendKey(k, p),
      ),
    ));

    // Profile-defined circle buttons
    for (final btn in _buttons) {
      if (!btn.visible) continue;
      final bind      = _binding(btn.bindId);
      final sz        = _sz(W, btn.size);
      final isSelected = _selectedId == btn.id;

      Widget child;
      if (btn.bindId == 'fire') {
        child = HudCircleBtn(
          size: sz, icon: _iconFor(bind.icon),
          keySeq: bind.keySequence, bindId: btn.bindId,
          editMode: _editMode, isFireBtn: true,
          accentColor: _accent,
          onPress:   () => _sendKey(bind.keySequence, true),
          onRelease: () => _sendKey(bind.keySequence, false),
        );
      } else if (bind.isToggle || bind.isHold) {
        child = HudCircleBtn(
          size: sz, icon: _iconFor(bind.icon),
          keySeq: bind.keySequence, bindId: btn.bindId,
          editMode: _editMode,
          isToggleBtn: true,
          isToggleOn:  _toggleStates[btn.bindId] ?? false,
          isMuteStyle: btn.bindId == 'mic' || btn.bindId == 'speaker',
          accentColor: _accent,
          onToggle: () => _handleToggle(
              btn.bindId, bind.keySequence, bind.isHold),
        );
      } else {
        child = HudCircleBtn(
          size: sz, icon: _iconFor(bind.icon),
          keySeq: bind.keySequence, bindId: btn.bindId,
          editMode: _editMode, accentColor: _accent,
          onPress:   () => _sendKey(bind.keySequence, true),
          onRelease: () => _sendKey(bind.keySequence, false),
        );
      }

      widgets.add(_DraggableBtn(
        key:      ValueKey(btn.id),
        btn:      btn, sz: sz, W: W, H: H,
        editMode: _editMode,
        selected: isSelected,
        opacity:  btn.opacity,
        onTap:    () => _selectBtn(btn.id),
        onDragEnd: (nx, ny) => setState(() {
          btn.x = nx; btn.y = ny;
        }),
        child: child,
      ));
    }

    return widgets;
  }

  // ── Edit outlines ──────────────────────────────────────────────────────────
  List<Widget> _buildEditOutlines(double W, double H) =>
      _buttons.map((btn) {
        final sz = _sz(W, btn.size);
        return Positioned(
          left: W * btn.x - sz / 2 - 3,
          top:  H * btn.y - sz / 2 - 3,
          child: IgnorePointer(
            child: Container(
              width: sz + 6, height: sz + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedId == btn.id
                      ? const Color(0xFF00E6C3)
                      : const Color(0x44FFFFFF),
                  width: _selectedId == btn.id ? 1.5 : 0.8,
                ),
              ),
            ),
          ),
        );
      }).toList();

  double _sz(double W, double frac) =>
      (W * frac).clamp(28.0, 140.0);

  static IconData _iconFor(String icon) {
    const m = <String, IconData>{
      'joystick': Icons.games,       'sprint': Icons.speed,
      'jump':     Icons.keyboard_arrow_up,
      'crouch':   Icons.keyboard_arrow_down,
      'ability1': Icons.flash_on,    'ability2': Icons.track_changes,
      'ultimate': Icons.star,
      'fire':     Icons.radio_button_unchecked,
      'scope':    Icons.search,      'reload': Icons.refresh,
      'interact': Icons.sports_mma,  'shop': Icons.store,
      'gunswitch':Icons.swap_horiz,  'knife': Icons.edit,
      'grenade':  Icons.radio_button_checked,
      'emoji':    Icons.emoji_emotions,
      'mappin':   Icons.location_on, 'mic': Icons.mic,
      'speaker':  Icons.volume_up,   'settings': Icons.settings,
      'chat':     Icons.chat_bubble_outline,
      'scoreboard': Icons.leaderboard,
      'primary':  Icons.horizontal_rule,
      'pistol':   Icons.lens_blur,
    };
    return m[icon] ?? Icons.crop_square;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DRAGGABLE BUTTON WRAPPER
// ══════════════════════════════════════════════════════════════════════════════
class _DraggableBtn extends StatelessWidget {
  final HudBtn   btn;
  final double   sz, W, H, opacity;
  final bool     editMode, selected;
  final Widget   child;
  final VoidCallback onTap;
  final void Function(double nx, double ny) onDragEnd;

  const _DraggableBtn({
    super.key,
    required this.btn, required this.sz,
    required this.W,   required this.H,
    required this.editMode, required this.selected,
    required this.opacity,  required this.child,
    required this.onTap,    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: W * btn.x - sz / 2,
    top:  H * btn.y - sz / 2,
    child: GestureDetector(
      onTap:      editMode ? onTap : null,
      onPanUpdate: editMode ? (d) {
        final nx = (btn.x + d.delta.dx / W).clamp(0.02, 0.98);
        final ny = (btn.y + d.delta.dy / H).clamp(0.02, 0.98);
        onDragEnd(nx, ny);
      } : null,
      child: Opacity(opacity: opacity, child: child),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// FINGER-DRAG MOUSE LAYER
// ══════════════════════════════════════════════════════════════════════════════
class _MouseDragLayer extends StatefulWidget {
  final void Function(int dx, int dy) onDelta;
  const _MouseDragLayer({required this.onDelta});

  @override
  State<_MouseDragLayer> createState() => _MouseDragLayerState();
}

class _MouseDragLayerState extends State<_MouseDragLayer> {
  static const double _sensitivity = 1.8;
  double _remX = 0, _remY = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onPanUpdate: (d) {
      _remX += d.delta.dx * _sensitivity;
      _remY += d.delta.dy * _sensitivity;
      final ix = _remX.truncate();
      final iy = _remY.truncate();
      if (ix != 0 || iy != 0) {
        _remX -= ix; _remY -= iy;
        widget.onDelta(ix, iy);
      }
    },
    onPanEnd: (_) { _remX = 0; _remY = 0; },
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
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(48, 48),
          painter: _RingCrosshairP(accentColor));
}

class _RingCrosshairP extends CustomPainter {
  final Color accent;
  const _RingCrosshairP(this.accent);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 3;

    // Outer glow
    canvas.drawCircle(c, r + 2,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Ring with 4 gaps at cardinal points
    const gapAngle = 0.18;
    final ringPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..color       = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.8
      ..strokeCap   = StrokeCap.round;

    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 4; i++) {
      final startAngle = i * (3.14159 / 2) + gapAngle;
      final sweepAngle = (3.14159 / 2) - gapAngle * 2;
      canvas.drawArc(rect, startAngle, sweepAngle, false, ringPaint);
    }

    // Centre dot
    canvas.drawCircle(c, 2.5,
        Paint()..color = Colors.white.withOpacity(0.90));

    // Faint inner ring
    canvas.drawCircle(c, r * 0.30,
        Paint()
          ..style       = PaintingStyle.stroke
          ..color       = Colors.white.withOpacity(0.15)
          ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_RingCrosshairP o) => o.accent != accent;
}

// ══════════════════════════════════════════════════════════════════════════════
// HUD BACKGROUND
// ══════════════════════════════════════════════════════════════════════════════
class _HudBg extends StatelessWidget {
  @override Widget build(BuildContext ctx) =>
      CustomPaint(painter: _HudBgP());
}

class _HudBgP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFF1A2330).withOpacity(0.18);
    for (double x = 0; x < s.width;  x += 40)
      for (double y = 0; y < s.height; y += 40)
        canvas.drawCircle(Offset(x, y), 0.6, p);
  }
  @override bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// CONNECTION DOT
// ══════════════════════════════════════════════════════════════════════════════
class _ConnDot extends StatelessWidget {
  final Color accent;
  const _ConnDot({required this.accent});

  @override
  Widget build(BuildContext context) {
    final conn  = context.watch<ConnModel>();
    final color = conn.isConnected
        ? const Color(0xFF00E6C3)
        : const Color(0xFF3D5166);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xBB0B1117),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(conn.isConnected
            ? (conn.deviceName ?? 'LINKED')
            : 'NO LINK',
            style: T.mono(8, color: color)),
      ]),
    );
  }
}

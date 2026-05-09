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
<<<<<<< Updated upstream
import '../widgets/weapon_bar.dart';
=======
import '../widgets/weapon_slot_bar.dart';
import '../widgets/hud_compact_edit_panel.dart';
>>>>>>> Stashed changes

/// Opened when user taps "DEPLOY" on a profile.
/// Full-screen immersive gameplay HUD — no editor UI.
/// Edit mode is a long-press toggle that shows drag handles.
class ControllerScreen extends StatefulWidget {
  final HudProfile profile;
  const ControllerScreen({super.key, required this.profile});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
<<<<<<< Updated upstream
  bool _editMode = false;
  bool _showTeamPanel = false;
=======
  // Edit state
  bool    _editMode    = false;
  String? _selectedId;
  double  _editSize    = 0.085;
  double  _editOpacity = 0.85;

  // Working button copies
  late List<HudBtn> _buttons;
  late List<HudBtn> _defaults;

  // Profile live values
  late String _accentHex;
  late double _sensitivity;

  // Toggle states
  final Map<String, bool> _toggleStates = {};
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
<<<<<<< Updated upstream
=======

    _buttons     = widget.profile.buttons.map((b) => b.clone()).toList();
    _defaults    = widget.profile.buttons.map((b) => b.clone()).toList();
    _accentHex   = widget.profile.accentHex;
    _sensitivity = widget.profile.sensitivityScale;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsm = context.read<WeaponSlotModel>();
      wsm.syncFromBindings(widget.profile.bindings);
      wsm.setAccent(_accent);
    });
>>>>>>> Stashed changes
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

<<<<<<< Updated upstream
  void _sendKey(BuildContext ctx, String key, bool pressed) {
    if (_editMode) return;
    final conn = ctx.read<ConnModel>();
    if (conn.mode == Transport.ble) {
      ctx.read<BleService>().sendKey(key, pressed: pressed);
=======
  Color get _accent {
    try { return Color(int.parse('FF${_accentHex.replaceAll('#','')}', radix: 16)); }
    catch (_) { return const Color(0xFFFF4655); }
  }

  // ── Key sending — routes to active transport ───────────────────────────────
  void _sendKey(String key, bool pressed) {
    if (_editMode) return;
    final conn = context.read<ConnModel>();
    final hid  = context.read<HidService>();

    // Priority: BT HID → USB HID → BLE → WiFi UDP
    if (hid.btHidActive || hid.usbHidActive) {
      hid.sendKey(key, pressed: pressed);
    } else if (conn.mode == Transport.ble) {
      context.read<BleService>().sendKey(key, pressed: pressed);
>>>>>>> Stashed changes
    } else {
      ctx.read<WifiService>().sendKey(key, pressed: pressed);
    }
  }

<<<<<<< Updated upstream
  KeyBinding _bind(String id) => widget.profile.bindings
      .firstWhere((b) => b.id == id,
          orElse: () => KeyBinding(id: id, label: id, keySequence: id, icon: id));

=======
  void _sendTap(String key) {
    _sendKey(key, true);
    Future.delayed(const Duration(milliseconds: 80), () => _sendKey(key, false));
  }

  void _sendMouse(int dx, int dy) {
    if (_editMode) return;
    final hid  = context.read<HidService>();
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
        orElse: () => KeyBinding(id:bindId, label:bindId, keySequence:bindId, icon:bindId),
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
    widget.profile.accentHex        = _accentHex;
    widget.profile.sensitivityScale = _sensitivity;
    context.read<WeaponSlotModel>().setAccent(_accent);
    ps.save(widget.profile);
    setState(() { _editMode = false; _selectedId = null; });
  }

  void _restoreDefaults() => setState(() {
    _buttons    = _defaults.map((b) => b.clone()).toList();
    _selectedId = null;
  });

  String? _selectedLabel() {
    if (_selectedId == null) return null;
    final b = _btn(_selectedId!);
    return b != null ? _binding(b.bindId).label : null;
  }

  // ══════════════════════════════════════════════════════════════════════════
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, box) {
        final W = box.maxWidth;
        final H = box.maxHeight;
        return GestureDetector(
          onLongPress: () => setState(() => _editMode = !_editMode),
          child: Stack(clipBehavior: Clip.none, children: [

            // ── 1. Subtle grid bg ──────────────────────────────────────────
            Positioned.fill(child: _HudBg()),

<<<<<<< Updated upstream
            // ── 2. Crosshair (centre) ──────────────────────────────────────
            Center(child: _Crosshair()),

            // ── 3. WEAPON BAR (bottom centre) ─────────────────────────────
            Positioned(
              bottom: 0, left: W * 0.32, right: W * 0.04,
              child: WeaponBar(editMode: _editMode),
            ),

            // ── 4. JOYSTICK (left) ─────────────────────────────────────────
            _Placed(x: 0.07, y: 0.52, w: W, h: H,
              size: _sz(W, 0.175),
              child: JoystickWidget(
                size: _sz(W, 0.175),
                editMode: _editMode,
                onKey: (k, p) => _sendKey(ctx, k, p),
              ),
            ),

            // ── 5. SPRINT (small, right of joystick) ──────────────────────
            _HudBtn(ctx:ctx, x:0.24, y:0.76, w:W, h:H, id:'sprint',
                bindId:'sprint', frac:0.075, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 6. MIC + SPEAKER (bottom-left) ────────────────────────────
            _HudBtn(ctx:ctx, x:0.05, y:0.90, w:W, h:H, id:'mic',
                bindId:'mic', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.11, y:0.90, w:W, h:H, id:'speaker',
                bindId:'speaker', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 7. SCOREBOARD / TEAM PANEL (top-left) ─────────────────────
            Positioned(
              left: W * 0.02, top: H * 0.05,
              child: _TeamPanel(visible: _showTeamPanel,
                onTap: () => setState(() => _showTeamPanel = !_showTeamPanel)),
            ),

            // ── 8. TOP-RIGHT utility strip ────────────────────────────────
            _HudBtn(ctx:ctx, x:0.68, y:0.06, w:W, h:H, id:'emoji',
                bindId:'emoji', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.74, y:0.06, w:W, h:H, id:'settings',
                bindId:'settings', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.68, y:0.20, w:W, h:H, id:'chat',
                bindId:'chat', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.74, y:0.20, w:W, h:H, id:'mappin',
                bindId:'map', frac:0.060, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 9. ABILITY CLUSTER (top-right) ────────────────────────────
            _HudBtn(ctx:ctx, x:0.81, y:0.20, w:W, h:H, id:'ability1',
                bindId:'ability1', frac:0.090, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.89, y:0.20, w:W, h:H, id:'ability2',
                bindId:'ability2', frac:0.082, editMode:_editMode, send:_sendKey,
                profile:widget.profile),
            _HudBtn(ctx:ctx, x:0.96, y:0.20, w:W, h:H, id:'ultimate',
                bindId:'ultimate', frac:0.078, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 10. PUNCH/INTERACT row ────────────────────────────────────
            _HudBtn(ctx:ctx, x:0.82, y:0.32, w:W, h:H, id:'interact',
                bindId:'interact', frac:0.078, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 11. JUMP (centre-right) ───────────────────────────────────
            _HudBtn(ctx:ctx, x:0.63, y:0.30, w:W, h:H, id:'jump',
                bindId:'jump', frac:0.082, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 12. RELOAD ────────────────────────────────────────────────
            _HudBtn(ctx:ctx, x:0.55, y:0.48, w:W, h:H, id:'reload',
                bindId:'reload', frac:0.076, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 13. THROW (grenade) ───────────────────────────────────────
            _HudBtn(ctx:ctx, x:0.42, y:0.62, w:W, h:H, id:'throw',
                bindId:'throw', frac:0.082, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 14. CROUCH ────────────────────────────────────────────────
            _HudBtn(ctx:ctx, x:0.63, y:0.65, w:W, h:H, id:'crouch',
                bindId:'crouch', frac:0.082, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 15. ADS / SCOPE (right side mid) ─────────────────────────
            _HudBtn(ctx:ctx, x:0.89, y:0.40, w:W, h:H, id:'ads',
                bindId:'ads', frac:0.090, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 16. FIRE (large, bottom-right) ───────────────────────────
            _FireBtn(ctx:ctx, x:0.88, y:0.67, w:W, h:H,
                bindId:'fire', frac:0.115, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 17. BUY MENU ──────────────────────────────────────────────
            _HudBtn(ctx:ctx, x:0.97, y:0.58, w:W, h:H, id:'buymenu',
                bindId:'buymenu', frac:0.068, editMode:_editMode, send:_sendKey,
                profile:widget.profile),

            // ── 18. GUN SWITCH ────────────────────────────────────────────
            Positioned(
              left: W * 0.29 - _sz(W, 0.065) / 2,
              top: H * 0.85  - _sz(W, 0.065) / 2,
              child: _GunSwitchBtn(
                size: _sz(W, 0.065),
                editMode: _editMode,
                onTap: () => _sendKey(ctx, 'TAB', true),
              ),
            ),

            // ── 19. Edit mode indicator ───────────────────────────────────
            if (_editMode)
              Positioned(
                top: 10, left: 0, right: 0,
                child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
=======
          // 1. Dot-grid background
          Positioned.fill(child: _HudBg()),

          // 2. Finger drag → mouse move
          if (!_editMode)
            Positioned.fill(child: _MouseDragLayer(
              sensitivity: _sensitivity,
              onDelta: _sendMouse,
            )),

          // 3. Ring crosshair
          Center(child: _RingCrosshair(accentColor: _accent)),

          // 4. Weapon slot bar (bottom centre-left)
          Positioned(
            bottom: 6, left: W * 0.28,
            child: WeaponSlotBar(
              model:    wsm,
              editMode: _editMode,
              onKeyTap: (key) => _sendTap(key),
            ),
          ),

          // 5. Draggable joystick
          _DraggableJoystick(
            W: W, H: H, editMode: _editMode,
            onKey: (k, p) => _sendKey(k, p),
          ),

          // 6. All HUD buttons
          ..._buildAllButtons(ctx, W, H),

          // 7. Edit outlines
          if (_editMode) ..._buildEditOutlines(W, H),

          // 8. Compact edit panel (top-centre)
          if (_editMode)
            Positioned(
              top: 0, left: W / 2 - 160,
              child: HudCompactEditPanel(
                selectedId:           _selectedId,
                selectedLabel:        _selectedLabel(),
                btnSize:              _editSize,
                btnOpacity:           _editOpacity,
                sensitivity:          _sensitivity,
                accentHex:            _accentHex,
                onSizeChanged:        (v) => _updateSelected(size: v),
                onOpacityChanged:     (v) => _updateSelected(opacity: v),
                onSensitivityChanged: (v) => setState(() => _sensitivity = v),
                onAccentChanged:      (hex) {
                  setState(() => _accentHex = hex);
                  wsm.setAccent(_accent);
                },
                onExit:    () => setState(() { _editMode = false; _selectedId = null; }),
                onRestore: _restoreDefaults,
                onSave:    _saveEdit,
              ),
            ),

          // 9. EDIT button (play mode)
          if (!_editMode)
            Positioned(
              top: 4, left: W / 2 - 34,
              child: GestureDetector(
                onTap: () => setState(() { _editMode = true; _selectedId = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
>>>>>>> Stashed changes
                  decoration: BoxDecoration(
                    color: T.teal.withOpacity(0.15),
                    border: Border.all(color: T.teal),
                  ),
                  child: Text('EDIT MODE  ·  LONG-PRESS TO EXIT',
                      style: T.mono(10, color: T.teal)),
                )),
              ),

            // ── 20. Back / exit HUD ───────────────────────────────────────
            Positioned(
              top: 8, left: 10,
              child: GestureDetector(
                onTap: () {
                  SystemChrome.setPreferredOrientations(DeviceOrientation.values);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: T.bg1.withOpacity(0.8),
                    border: Border.all(color: T.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
<<<<<<< Updated upstream
                    const Icon(Icons.arrow_back_ios_new, color: T.grey, size: 12),
                    const SizedBox(width: 4),
                    Text('EXIT', style: T.mono(9, color: T.grey)),
=======
                    const Icon(Icons.edit, color: Color(0xAAFFFFFF), size: 12),
                    const SizedBox(width: 5),
                    Text('EDIT', style: T.mono(9, color: const Color(0xAAFFFFFF))),
>>>>>>> Stashed changes
                  ]),
                ),
              ),
            ),

<<<<<<< Updated upstream
            // ── 21. Connection status ─────────────────────────────────────
            Positioned(
              top: 8, right: 10,
              child: _ConnDot(),
            ),
          ]),
        );
=======
          // 10. Back button
          Positioned(
            top: 4, left: 6,
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
>>>>>>> Stashed changes
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════════

<<<<<<< Updated upstream
double _sz(double W, double frac) => (W * frac).clamp(28.0, 140.0);

/// Positioned HUD button helper
class _HudBtn extends StatelessWidget {
  final BuildContext ctx;
  final double x, y, w, h, frac;
  final String id, bindId;
  final bool editMode;
  final HudProfile profile;
  final void Function(BuildContext, String, bool) send;

  const _HudBtn({
    required this.ctx, required this.x, required this.y,
    required this.w, required this.h, required this.frac,
    required this.id, required this.bindId,
    required this.editMode, required this.profile, required this.send,
  });

  @override
  Widget build(BuildContext context) {
    final sz = _sz(w, frac);
    final binding = profile.bindings.firstWhere(
      (b) => b.id == bindId,
      orElse: () => KeyBinding(id: bindId, label: bindId, keySequence: bindId, icon: bindId),
    );
    return Positioned(
      left: w * x - sz / 2,
      top:  h * y - sz / 2,
      child: HudCircleBtn(
        size: sz,
        icon: _iconFor(binding.icon),
        keySeq: binding.keySequence,
        editMode: editMode,
        onPress:   () => send(ctx, binding.keySequence, true),
        onRelease: () => send(ctx, binding.keySequence, false),
      ),
    );
  }

  static IconData _iconFor(String icon) {
    const m = <String, IconData>{
      'joystick': Icons.games, 'sprint': Icons.speed,
      'jump': Icons.keyboard_arrow_up, 'crouch': Icons.keyboard_arrow_down,
      'ability1': Icons.flash_on, 'ability2': Icons.track_changes,
      'ultimate': Icons.star, 'fire': Icons.gps_fixed,
      'scope': Icons.search, 'reload': Icons.refresh,
      'interact': Icons.sports_mma, 'shop': Icons.store,
      'gunswitch': Icons.swap_horiz, 'knife': Icons.edit,
      'grenade': Icons.radio_button_checked, 'emoji': Icons.emoji_emotions,
      'mappin': Icons.location_on, 'mic': Icons.mic,
      'speaker': Icons.volume_up, 'settings': Icons.settings,
      'chat': Icons.chat_bubble_outline, 'scoreboard': Icons.leaderboard,
    };
    return m[icon] ?? Icons.crop_square;
  }
}

/// Large fire button (bullet icon)
class _FireBtn extends StatelessWidget {
  final BuildContext ctx;
  final double x, y, w, h, frac;
  final String bindId;
  final bool editMode;
  final HudProfile profile;
  final void Function(BuildContext, String, bool) send;

  const _FireBtn({
    required this.ctx, required this.x, required this.y,
    required this.w, required this.h, required this.frac,
    required this.bindId, required this.editMode,
    required this.profile, required this.send,
  });

  @override
  Widget build(BuildContext context) {
    final sz = _sz(w, frac);
    final binding = profile.bindings.firstWhere(
      (b) => b.id == bindId,
      orElse: () => const KeyBinding(id:'fire', label:'Fire', keySequence:'Mouse_L', icon:'fire'),
    );
    return Positioned(
      left: w * x - sz / 2,
      top:  h * y - sz / 2,
      child: HudCircleBtn(
        size: sz,
        icon: Icons.radio_button_unchecked,   // bullet-ish
        keySeq: binding.keySequence,
        isFireBtn: true,
        editMode: editMode,
        onPress:   () => send(ctx, binding.keySequence, true),
        onRelease: () => send(ctx, binding.keySequence, false),
      ),
    );
  }
}

/// Gun switch – square bordered box (like FF screenshot)
class _GunSwitchBtn extends StatefulWidget {
  final double size;
  final bool editMode;
  final VoidCallback onTap;
  const _GunSwitchBtn({required this.size, required this.editMode, required this.onTap});
=======
    for (final btn in _buttons) {
      if (!btn.visible) continue;
      final bind = _binding(btn.bindId);
      final sz   = _sz(W, btn.size);

      final isFire   = btn.bindId == 'fire' || btn.bindId == 'fire_left';
      final isToggle = bind.isToggle || bind.isHold;
      final isMute   = btn.bindId == 'mic' || btn.bindId == 'speaker';

      final child = HudCircleBtn(
        size:        sz,
        iconKey:     bind.icon,
        keySeq:      bind.keySequence,
        bindId:      btn.bindId,
        editMode:    _editMode,
        isFireBtn:   isFire && !isToggle,
        isToggleBtn: isToggle,
        isToggleOn:  _toggleStates[btn.bindId] ?? false,
        isMuteStyle: isMute,
        accentColor: _accent,
        onPress:     () => _sendKey(bind.keySequence, true),
        onRelease:   () => _sendKey(bind.keySequence, false),
        onToggle:    () => _handleToggle(btn.bindId, bind.keySequence, bind.isHold),
      );

      widgets.add(_DraggableBtn(
        key:      ValueKey(btn.id),
        btn:      btn, sz: sz, W: W, H: H,
        editMode: _editMode,
        opacity:  btn.opacity,
        onTap:    () => _selectBtn(btn.id),
        onDragEnd: (nx, ny) => setState(() { btn.x = nx; btn.y = ny; }),
        child:    child,
      ));
    }

    return widgets;
  }

  List<Widget> _buildEditOutlines(double W, double H) =>
      _buttons.map((btn) {
        final sz = _sz(W, btn.size);
        return Positioned(
          left: W * btn.x - sz / 2 - 3,
          top:  H * btn.y - sz / 2 - 3,
          child: IgnorePointer(child: Container(
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
  final bool   editMode;
  final Widget child;
  final VoidCallback onTap;
  final void Function(double, double) onDragEnd;

  const _DraggableBtn({
    super.key,
    required this.btn, required this.sz, required this.W, required this.H,
    required this.editMode, required this.opacity, required this.child,
    required this.onTap, required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: W * btn.x - sz / 2,
    top:  H * btn.y - sz / 2,
    child: GestureDetector(
      onTap:       editMode ? onTap : null,
      onPanUpdate: editMode ? (d) {
        final nx = (btn.x + d.delta.dx / W).clamp(0.01, 0.99);
        final ny = (btn.y + d.delta.dy / H).clamp(0.01, 0.99);
        onDragEnd(nx, ny);
      } : null,
      child: Opacity(opacity: opacity, child: child),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// DRAGGABLE JOYSTICK
// ══════════════════════════════════════════════════════════════════════════════
class _DraggableJoystick extends StatefulWidget {
  final double W, H;
  final bool   editMode;
  final void Function(String, bool) onKey;
  const _DraggableJoystick({required this.W, required this.H,
      required this.editMode, required this.onKey});

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
      top:  widget.H * _fy - sz / 2,
      child: GestureDetector(
        onPanUpdate: widget.editMode ? (d) => setState(() {
          _fx = (_fx + d.delta.dx / widget.W).clamp(0.02, 0.45);
          _fy = (_fy + d.delta.dy / widget.H).clamp(0.30, 0.95);
        }) : null,
        child: JoystickWidget(
          size: sz, editMode: widget.editMode, onKey: widget.onKey,
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
>>>>>>> Stashed changes

  @override
  State<_GunSwitchBtn> createState() => _GunSwitchBtnState();
}

<<<<<<< Updated upstream
class _GunSwitchBtnState extends State<_GunSwitchBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final sz = widget.size;
    return GestureDetector(
      onTapDown: (_) { setState(() => _down = true);  widget.onTap(); },
      onTapUp:   (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: Container(
        width: sz, height: sz,
        decoration: BoxDecoration(
          color: _down ? T.red.withOpacity(0.3) : const Color(0xAA111820),
          border: Border.all(
            color: widget.editMode ? T.teal : (_down ? T.red : const Color(0x55FFFFFF)),
            width: 1.5,
          ),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.swap_horiz, color: const Color(0xCCFFFFFF), size: sz * 0.45),
          // Small X badge (like FF)
          Positioned(top: 2, right: 2,
            child: Container(
              width: sz * 0.28, height: sz * 0.28,
              decoration: BoxDecoration(
                color: _down ? Colors.white : T.red,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('×',
                style: T.raj(sz * 0.18, color: Colors.white))),
            ),
          ),
        ]),
      ),
    );
  }
=======
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
        _remX -= ix; _remY -= iy;
        widget.onDelta(ix, iy);
      }
    },
    onPanEnd: (_) { _remX = 0; _remY = 0; },
    child: const SizedBox.expand(),
  );
>>>>>>> Stashed changes
}

/// Team panel (top-left scoreboard)
class _TeamPanel extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _TeamPanel({required this.visible, required this.onTap});

  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Toggle button
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xBB0B1117),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline, color: T.grey, size: 14),
            const SizedBox(width: 4),
            Icon(visible ? Icons.expand_less : Icons.expand_more,
                color: T.grey, size: 14),
          ]),
        ),
      ),
      if (visible) ...[
        const SizedBox(height: 2),
        _teamRow('Player 1', T.red),
        _teamRow('Player 2', T.red),
        _teamRow('Player 3', T.red),
      ],
    ]);
  }

  Widget _teamRow(String name, Color accent) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xBB0B1117),
      border: Border(left: BorderSide(color: accent, width: 2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, color: accent),
      const SizedBox(width: 6),
      Text(name, style: T.mono(9, color: T.white)),
    ]),
  );
=======
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(46, 46), painter: _RingCrosshairP(accentColor));
}

class _RingCrosshairP extends CustomPainter {
  final Color accent;
  const _RingCrosshairP(this.accent);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2 - 3;
    const gap = 0.20;
    const pi  = 3.14159265;

    canvas.drawCircle(c, r + 2,
        Paint()..color = Colors.white.withOpacity(0.07)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.88)
      ..strokeWidth = 1.8..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(rect, i * (pi / 2) + gap, pi / 2 - gap * 2, false, rp);
    }
    canvas.drawCircle(c, 2.5, Paint()..color = Colors.white.withOpacity(0.92));
    canvas.drawCircle(c, r * 0.28,
        Paint()..style = PaintingStyle.stroke
               ..color = Colors.white.withOpacity(0.14)..strokeWidth = 0.8);
  }

  @override bool shouldRepaint(_RingCrosshairP o) => o.accent != accent;
>>>>>>> Stashed changes
}

/// Crosshair drawn in canvas
class _Crosshair extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(22, 22), painter: _CrossP());
}

class _CrossP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = T.teal.withOpacity(0.75)..strokeWidth = 1.5;
    final cx = s.width / 2; final cy = s.height / 2;
    const g = 3.0; const l = 6.0;
    canvas.drawLine(Offset(cx-l-g, cy), Offset(cx-g, cy), p);
    canvas.drawLine(Offset(cx+g, cy), Offset(cx+l+g, cy), p);
    canvas.drawLine(Offset(cx, cy-l-g), Offset(cx, cy-g), p);
    canvas.drawLine(Offset(cx, cy+g), Offset(cx, cy+l+g), p);
    canvas.drawCircle(Offset(cx, cy), 1.5, p..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(_) => false;
}

/// HUD dot-grid background
class _HudBg extends StatelessWidget {
  @override Widget build(BuildContext ctx) => CustomPaint(painter: _HudBgP());
}

class _HudBgP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
<<<<<<< Updated upstream
    final p = Paint()..color = T.bg3.withOpacity(0.25);
    for (double x = 0; x < s.width;  x += 38) {
      for (double y = 0; y < s.height; y += 38) {
        canvas.drawCircle(Offset(x, y), 0.7, p);
      }
    }
    final glow = Paint()
      ..color = T.red.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(s.width, s.height), 120, glow);
=======
    final p = Paint()..color = const Color(0xFF1A2330).withOpacity(0.16);
    for (double x = 0; x < s.width;  x += 40)
      for (double y = 0; y < s.height; y += 40)
        canvas.drawCircle(Offset(x, y), 0.6, p);
>>>>>>> Stashed changes
  }
  @override bool shouldRepaint(_) => false;
}

/// Connection dot in top-right corner
class _ConnDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();
<<<<<<< Updated upstream
    final color = conn.isConnected ? T.teal : T.greyDim;
=======
    final hid  = context.watch<HidService>();
    final active = conn.isConnected || hid.btHidActive || hid.usbHidActive;
    final label  = hid.btHidActive  ? 'BT HID'
                 : hid.usbHidActive ? 'USB HID'
                 : conn.isConnected ? (conn.deviceName ?? 'LINKED')
                 : 'NO LINK';
    final color  = active ? const Color(0xFF00E6C3) : const Color(0xFF3D5166);

>>>>>>> Stashed changes
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: T.bg1.withOpacity(0.75),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
<<<<<<< Updated upstream
        Text(conn.isConnected
            ? '${conn.deviceName ?? 'LINKED'}  ${conn.latencyMs}ms'
            : 'NO LINK',
          style: T.mono(8, color: color)),
=======
        Text(label, style: T.mono(8, color: color)),
>>>>>>> Stashed changes
      ]),
    );
  }
}

/// Placed helper (absolute positioned centred on fractional coords)
class _Placed extends StatelessWidget {
  final double x, y, w, h, size;
  final Widget child;
  const _Placed({required this.x, required this.y, required this.w,
    required this.h, required this.size, required this.child});

  @override
  Widget build(BuildContext context) => Positioned(
    left: w * x - size / 2,
    top:  h * y - size / 2,
    child: child,
  );
}

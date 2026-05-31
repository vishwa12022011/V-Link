import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:vlink/services/webrtc_service.dart';
import 'package:vlink/models/app_models.dart';
import 'package:vlink/services/profile_service.dart';
import 'package:vlink/services/ble_service.dart';
import 'package:vlink/services/wifi_service.dart';
import 'package:vlink/services/hid_service.dart';
import 'package:vlink/utils/app_theme.dart';
import 'package:vlink/widgets/joystick_widget.dart';
import 'package:vlink/widgets/hud_circle_btn.dart';
import 'package:vlink/widgets/weapon_slot_bar.dart';
import 'package:vlink/widgets/hud_compact_edit_panel.dart';

class ControllerScreen extends StatefulWidget {
  final HudProfile profile;
  const ControllerScreen({super.key, required this.profile});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool    _editMode    = false;
  String? _selectedId;
  double  _editSize    = 0.085;
  double  _editOpacity = 0.85;

  late List<HudBtn> _buttons;
  late List<HudBtn> _defaults;

  late String _accentHex;
  late double _sensitivity;

  final Map<String, bool> _toggleStates = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _buttons     = widget.profile.buttons.map((b) => b.clone()).toList();
    _defaults    = widget.profile.buttons.map((b) => b.clone()).toList();
    _accentHex   = widget.profile.accentHex;
    _sensitivity = widget.profile.sensitivityScale;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsm = context.read<WeaponSlotModel>();
      wsm.syncFromBindings(widget.profile.bindings);
      wsm.setAccent(accent);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Color get accent {
    try { return Color(int.parse('FF${_accentHex.replaceAll('#','')}', radix: 16)); }
    catch (_) { return const Color(0xFFFF4655); }
  }

  void _sendKey(String key, bool pressed) {
    if (_editMode) return;
    final conn = context.read<ConnModel>();
    final hid  = context.read<HidService>();

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

  void _handleToggle(String bindId, String keySeq, bool isHold) {
    final nowOn = !(_toggleStates[bindId] ?? false);
    setState(() => _toggleStates[bindId] = nowOn);
    if (isHold) {
      _sendKey(keySeq, nowOn);
    } else {
      _sendTap(keySeq);
    }
  }

  KeyBinding _binding(String bindId) =>
    widget.profile.bindings.values.expand((b) => b).firstWhere((b) => b.id == bindId,
        orElse: () => KeyBinding(id:bindId, label:bindId, keySequence:bindId, icon:bindId));

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

  void _updateSelected({double? size, double? opacity, String? newName}) {
    if (_selectedId == null) {
      if (newName != null) {
        setState(() => widget.profile.name = newName);
      }
      return;
    }
    if (newName != null) {
      setState(() => widget.profile.name = newName);
      return;
    }
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
    context.read<WeaponSlotModel>().setAccent(accent);
    ps.save(widget.profile);
    setState(() { _editMode = false; _selectedId = null; });
  }

  void _restoreDefaults() => setState(() {
    _buttons    = _defaults.map((b) => b.clone()).toList();
    _selectedId = null;
  });

  String? _selectedLabel() {
    if (_selectedId == null) return null;
    if (_selectedId == 'joystick') return 'Joystick';
    if (_selectedId == 'weapon_bar') return 'Weapon Bar';
    final b = _btn(_selectedId!);
    return b != null ? _binding(b.bindId).label : null;
  }

  @override
  Widget build(BuildContext context) {
    final wsm = context.watch<WeaponSlotModel>();
    final wrtc = context.watch<WebRtcService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (event) {},
        child: RawGestureDetector(
          gestures: {
            EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              () => EagerGestureRecognizer(),
              (instance) {},
            ),
          },
          child: LayoutBuilder(builder: (ctx, box) {
            final W = box.maxWidth;
            final H = box.maxHeight;

            return Stack(clipBehavior: Clip.none, children: [
              // LAYER 1: VIDEO STREAM (Dynamic)
              if (wrtc.isConnected)
                Positioned.fill(
                  child: RTCVideoView(
                    wrtc.remoteRenderer, 
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                  ),
                )
              else
                Positioned.fill(child: _HudBg()),

              // LAYER 2: Mouse Input
              if (!_editMode)
                Positioned.fill(child: _MouseDragLayer(sensitivity: _sensitivity, onDelta: _sendMouse)),

              // LAYER 3: HUD Elements
              Center(child: _RingCrosshair(accentColor: accent)),

              _DraggableWeaponBar(
                W: W, H: H, editMode: _editMode,
                onKey: (k, p) => _sendKey(k, p),
                onSelect: () => _selectBtn('weapon_bar'),
                child: WeaponSlotBar(model: wsm, editMode: _editMode, onKeyTap: _sendTap),
              ),

              _DraggableJoystick(
                W: W, H: H, editMode: _editMode,
                onKey: (k, p) => _sendKey(k, p),
                onSelect: () => _selectBtn('joystick'),
              ),

              ..._buildAllButtons(ctx, W, H),
              if (_editMode) ..._buildEditOutlines(W, H),

              // UI Panels (Edit Panel)
              if (_editMode)
                Positioned(
                  top: 0, left: W / 2 - 160,
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
                      wsm.setAccent(accent);
                    },
                    onNameChanged: (newName) => _updateSelected(newName: newName),
                    onExit: () => setState(() { _editMode = false; _selectedId = null; }),
                    onRestore: _restoreDefaults,
                    onSave: _saveEdit,
                  ),
                ),

              // DYNAMIC WEBRTC TOGGLE
              if (wrtc.isConnected)
                Positioned(
                  top: 4, right: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xBB0B1117), 
                      border: Border.all(color: const Color(0xFF00E6C3))
                    ),
                    child: Row(children: [
                      Text("WebRTC", style: T.mono(8, color: Colors.white)),
                      Switch(
                        value: true,
                        onChanged: (_) => wrtc.disconnect(),
                        activeTrackColor: const Color(0xFF00E6C3),
                        thumbColor: WidgetStateProperty.all(Colors.white),
                      )
                    ]),
                  ),
                ),

              // Global Status Dot
              Positioned(top: 4, right: 6, child: _ConnDot(accent: accent)),
              
              // Back Button
              Positioned(
                top: 4, left: 6,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xBB0B1117), border: Border.all(color: const Color(0x33FFFFFF))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_back_ios_new, color: T.grey, size: 10),
                      const SizedBox(width: 3),
                      Text('EXIT', style: T.mono(8, color: T.grey)),
                    ]),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  List<Widget> _buildAllButtons(BuildContext ctx, double W, double H) {
    final widgets = <Widget>[];

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
        accentColor: accent,
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

class _DraggableJoystick extends StatefulWidget {
  final double W, H;
  final bool   editMode;
  final void Function(String, bool) onKey;
  final VoidCallback onSelect;
  const _DraggableJoystick({required this.W, required this.H,
      required this.editMode, required this.onKey, required this.onSelect});

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
        onTap: widget.editMode ? widget.onSelect : null,
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

class _DraggableWeaponBar extends StatefulWidget {
  final double W, H;
  final bool editMode;
  final void Function(String, bool) onKey;
  final VoidCallback onSelect;
  final Widget child;

  const _DraggableWeaponBar(
      {required this.W,
      required this.H,
      required this.editMode,
      required this.onKey,
      required this.onSelect,
      required this.child});

  @override
  State<_DraggableWeaponBar> createState() => _DraggableWeaponBarState();
}

class _DraggableWeaponBarState extends State<_DraggableWeaponBar> {
  double _fx = 0.28, _fy = 0.95;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.W * _fx,
      top: widget.H * _fy,
      child: GestureDetector(
        onTap: widget.editMode ? widget.onSelect : null,
        onPanUpdate: widget.editMode
            ? (d) => setState(() {
                  _fx = (_fx + d.delta.dx / widget.W).clamp(0.02, 0.80);
                  _fy = (_fy + d.delta.dy / widget.H).clamp(0.05, 0.95);
                })
            : null,
        child: widget.child,
      ),
    );
  }
}


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
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        _remX += details.delta.dx * widget.sensitivity;
        _remY += details.delta.dy * widget.sensitivity;
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
}

class _RingCrosshair extends StatelessWidget {
  final Color accentColor;
  const _RingCrosshair({required this.accentColor});

  @override
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
        Paint()..color = Colors.white.withValues(alpha: 0.07)
               ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final rp = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 1.8..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(rect, i * (pi / 2) + gap, pi / 2 - gap * 2, false, rp);
    }
    canvas.drawCircle(c, 2.5, Paint()..color = Colors.white.withValues(alpha: 0.92));
    canvas.drawCircle(c, r * 0.28,
        Paint()..style = PaintingStyle.stroke
               ..color = Colors.white.withValues(alpha: 0.14)..strokeWidth = 0.8);
  }

  @override bool shouldRepaint(_RingCrosshairP o) => o.accent != accent;
}

class _HudBg extends StatelessWidget {
  @override Widget build(BuildContext ctx) => CustomPaint(painter: _HudBgP());
}

class _HudBgP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFF1A2330).withValues(alpha: 0.16);
    for (double x = 0; x < s.width;  x += 40)
      for (double y = 0; y < s.height; y += 40)
        canvas.drawCircle(Offset(x, y), 0.6, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _ConnDot extends StatelessWidget {
  final Color accent;
  const _ConnDot({required this.accent});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();
    final hid  = context.watch<HidService>();
    final active = conn.isConnected || hid.btHidActive || hid.usbHidActive;
    final label  = hid.btHidActive  ? 'BT HID'
                 : hid.usbHidActive ? 'USB HID'
                 : conn.isConnected ? (conn.deviceName ?? 'LINKED')
                 : 'NO LINK';
    final color  = active ? const Color(0xFF00E6C3) : const Color(0xFF3D5166);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xBB0B1117),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label, style: T.mono(8, color: color)),
      ]),
    );
  }
}
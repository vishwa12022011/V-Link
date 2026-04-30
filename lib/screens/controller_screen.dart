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
import '../widgets/weapon_bar.dart';

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
  bool _editMode = false;
  bool _showTeamPanel = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _sendKey(BuildContext ctx, String key, bool pressed) {
    if (_editMode) return;
    final conn = ctx.read<ConnModel>();
    if (conn.mode == Transport.ble) {
      ctx.read<BleService>().sendKey(key, pressed: pressed);
    } else {
      ctx.read<WifiService>().sendKey(key, pressed: pressed);
    }
  }

  KeyBinding _bind(String id) => widget.profile.bindings
      .firstWhere((b) => b.id == id,
          orElse: () => KeyBinding(id: id, label: id, keySequence: id, icon: id));

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
                    const Icon(Icons.arrow_back_ios_new, color: T.grey, size: 12),
                    const SizedBox(width: 4),
                    Text('EXIT', style: T.mono(9, color: T.grey)),
                  ]),
                ),
              ),
            ),

            // ── 21. Connection status ─────────────────────────────────────
            Positioned(
              top: 8, right: 10,
              child: _ConnDot(),
            ),
          ]),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════════════════════════════════

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

  @override
  State<_GunSwitchBtn> createState() => _GunSwitchBtnState();
}

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
}

/// Team panel (top-left scoreboard)
class _TeamPanel extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _TeamPanel({required this.visible, required this.onTap});

  @override
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
  @override Widget build(BuildContext ctx) =>
      CustomPaint(painter: _HudBgP());
}

class _HudBgP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
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
  }
  @override bool shouldRepaint(_) => false;
}

/// Connection dot in top-right corner
class _ConnDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();
    final color = conn.isConnected ? T.teal : T.greyDim;
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
        Text(conn.isConnected
            ? '${conn.deviceName ?? 'LINKED'}  ${conn.latencyMs}ms'
            : 'NO LINK',
          style: T.mono(8, color: color)),
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

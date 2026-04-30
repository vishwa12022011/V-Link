import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// ══════════════════════════════════════════════════════════════════════════════
// KEY BINDING
// ══════════════════════════════════════════════════════════════════════════════
class KeyBinding {
  final String id;
  final String label;
  final String keySequence;
  final String icon;

  const KeyBinding({
    required this.id,
    required this.label,
    required this.keySequence,
    required this.icon,
  });

  factory KeyBinding.fromJson(Map<String, dynamic> j) => KeyBinding(
        id: j['id'], label: j['label'],
        keySequence: j['keySequence'], icon: j['icon'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'label': label,
        'keySequence': keySequence, 'icon': icon,
      };

  KeyBinding copyWith({String? keySequence, String? label}) => KeyBinding(
        id: id, icon: icon,
        label: label ?? this.label,
        keySequence: keySequence ?? this.keySequence,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// HUD BUTTON CONFIG
// ══════════════════════════════════════════════════════════════════════════════
class HudBtn {
  final String id;
  final String bindId;
  double x, y, size, opacity;
  bool visible;

  HudBtn({
    required this.id, required this.bindId,
    required this.x, required this.y,
    required this.size,
    this.opacity = 0.85, this.visible = true,
  });

  factory HudBtn.fromJson(Map<String, dynamic> j) => HudBtn(
        id: j['id'], bindId: j['bindId'],
        x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble(),
        size: (j['size'] as num).toDouble(),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.85,
        visible: j['visible'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'bindId': bindId,
        'x': x, 'y': y, 'size': size,
        'opacity': opacity, 'visible': visible,
      };

  HudBtn clone() => HudBtn(
    id: id, bindId: bindId, x: x, y: y, size: size,
    opacity: opacity, visible: visible,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// HUD PROFILE
// ══════════════════════════════════════════════════════════════════════════════
class HudProfile {
  String id, name, tag;
  int latencyMs;
  String accentHex;
  List<KeyBinding> bindings;
  List<HudBtn> buttons;
  DateTime updatedAt;

  HudProfile({
    required this.id, required this.name, required this.tag,
    required this.latencyMs, required this.accentHex,
    required this.bindings, required this.buttons,
    required this.updatedAt,
  });

  factory HudProfile.fromJson(Map<String, dynamic> j) => HudProfile(
        id: j['id'], name: j['name'], tag: j['tag'] ?? 'ESP32',
        latencyMs: j['latencyMs'] as int? ?? 1,
        accentHex: j['accentHex'] ?? '#FF4655',
        bindings: (j['bindings'] as List).map((e) => KeyBinding.fromJson(e)).toList(),
        buttons:  (j['buttons']  as List).map((e) => HudBtn.fromJson(e)).toList(),
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'tag': tag,
        'latencyMs': latencyMs, 'accentHex': accentHex,
        'bindings': bindings.map((b) => b.toJson()).toList(),
        'buttons':  buttons.map((b)  => b.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  // ── Defaults ────────────────────────────────────────────────────────────
  static HudProfile get defaults {
    final bindings = <KeyBinding>[
      const KeyBinding(id:'walk',      label:'Walk',           keySequence:'WASD',     icon:'joystick'),
      const KeyBinding(id:'sprint',    label:'Sprint',         keySequence:'L-SHIFT',  icon:'sprint'),
      const KeyBinding(id:'jump',      label:'Jump',           keySequence:'SPACE',    icon:'jump'),
      const KeyBinding(id:'crouch',    label:'Crouch',         keySequence:'L-CTRL',   icon:'crouch'),
      const KeyBinding(id:'ability1',  label:'Ability 1',      keySequence:'E',        icon:'ability1'),
      const KeyBinding(id:'ability2',  label:'Ability 2',      keySequence:'Q',        icon:'ability2'),
      const KeyBinding(id:'ultimate',  label:'Ultimate',       keySequence:'X',        icon:'ultimate'),
      const KeyBinding(id:'fire',      label:'Fire',           keySequence:'Mouse_L',  icon:'fire'),
      const KeyBinding(id:'ads',       label:'ADS / Scope',    keySequence:'Mouse_R',  icon:'scope'),
      const KeyBinding(id:'reload',    label:'Reload',         keySequence:'R',        icon:'reload'),
      const KeyBinding(id:'interact',  label:'Interact',       keySequence:'F',        icon:'interact'),
      const KeyBinding(id:'buymenu',   label:'Buy Menu',       keySequence:'B',        icon:'shop'),
      const KeyBinding(id:'gunswitch', label:'Gun Switch',     keySequence:'TAB',      icon:'gunswitch'),
      const KeyBinding(id:'knife',     label:'Melee',          keySequence:'3',        icon:'knife'),
      const KeyBinding(id:'throw',     label:'Throwable',      keySequence:'4',        icon:'grenade'),
      const KeyBinding(id:'emoji',     label:'Emoji',          keySequence:'T',        icon:'emoji'),
      const KeyBinding(id:'map',       label:'Map Marker',     keySequence:'M',        icon:'mappin'),
      const KeyBinding(id:'mic',       label:'Mic',            keySequence:'V',        icon:'mic'),
      const KeyBinding(id:'speaker',   label:'Speaker',        keySequence:'U',        icon:'speaker'),
      const KeyBinding(id:'settings',  label:'Settings',       keySequence:'ESC',      icon:'settings'),
      const KeyBinding(id:'chat',      label:'Chat',           keySequence:'ENTER',    icon:'chat'),
      const KeyBinding(id:'scoreboard',label:'Scoreboard',     keySequence:'TAB',      icon:'scoreboard'),
    ];

    // Landscape layout (0..1 fractional). Based on the FF screenshot.
    // x=0 left, x=1 right, y=0 top, y=1 bottom
    final buttons = [
      // LEFT ZONE
      HudBtn(id:'b_walk',      bindId:'walk',       x:0.12, y:0.62, size:0.175), // big joystick
      HudBtn(id:'b_sprint',    bindId:'sprint',     x:0.26, y:0.72, size:0.085),
      HudBtn(id:'b_mic',       bindId:'mic',        x:0.05, y:0.90, size:0.065),
      HudBtn(id:'b_speaker',   bindId:'speaker',    x:0.12, y:0.90, size:0.065),
      // TOP-LEFT
      HudBtn(id:'b_scoreboard',bindId:'scoreboard', x:0.22, y:0.28, size:0.080),
      HudBtn(id:'b_emoji',     bindId:'emoji',      x:0.68, y:0.08, size:0.065),
      HudBtn(id:'b_settings',  bindId:'settings',   x:0.76, y:0.08, size:0.065),
      HudBtn(id:'b_chat',      bindId:'chat',       x:0.68, y:0.18, size:0.065),
      HudBtn(id:'b_mappin',    bindId:'map',        x:0.76, y:0.18, size:0.065),
      // CENTRE
      HudBtn(id:'b_gunswitch', bindId:'gunswitch',  x:0.29, y:0.88, size:0.070),
      // WEAPON SLOT BAR (bottom centre)
      HudBtn(id:'b_knife',     bindId:'knife',      x:0.50, y:0.92, size:0.070),
      HudBtn(id:'b_throw',     bindId:'throw',      x:0.42, y:0.70, size:0.085),
      // RIGHT ZONE — abilities cluster
      HudBtn(id:'b_ability1',  bindId:'ability1',   x:0.82, y:0.24, size:0.095),
      HudBtn(id:'b_ability2',  bindId:'ability2',   x:0.91, y:0.24, size:0.085),
      HudBtn(id:'b_ultimate',  bindId:'ultimate',   x:0.97, y:0.24, size:0.080),
      HudBtn(id:'b_interact',  bindId:'interact',   x:0.82, y:0.35, size:0.080),
      // RIGHT ZONE — actions
      HudBtn(id:'b_jump',      bindId:'jump',       x:0.65, y:0.40, size:0.085),
      HudBtn(id:'b_crouch',    bindId:'crouch',     x:0.62, y:0.62, size:0.085),
      HudBtn(id:'b_reload',    bindId:'reload',     x:0.55, y:0.50, size:0.080),
      HudBtn(id:'b_ads',       bindId:'ads',        x:0.88, y:0.40, size:0.095),
      HudBtn(id:'b_fire',      bindId:'fire',       x:0.88, y:0.60, size:0.115), // big fire btn
      HudBtn(id:'b_buymenu',   bindId:'buymenu',    x:0.97, y:0.55, size:0.075),
    ];

    return HudProfile(
      id: const Uuid().v4(),
      name: 'VALORANT_PRO_V1',
      tag: 'ESP32-S3-HID',
      latencyMs: 1,
      accentHex: '#FF4655',
      bindings: bindings,
      buttons: buttons,
      updatedAt: DateTime.now(),
    );
  }

  String timeAgo() {
    final d = DateTime.now().difference(updatedAt);
    if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
    if (d.inHours   < 24) return '${d.inHours}H AGO';
    return '${d.inDays}D AGO';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE MODELS
// ══════════════════════════════════════════════════════════════════════════════
enum Transport { ble, wifi }
enum ConnStatus { disconnected, scanning, connecting, connected }

class ConnModel extends ChangeNotifier {
  Transport mode = Transport.ble;
  ConnStatus status = ConnStatus.disconnected;
  String? deviceName;
  int latencyMs = 0;
  final List<String> logs = [];

  bool get isConnected => status == ConnStatus.connected;

  void setMode(Transport m) { mode = m; notifyListeners(); }
  void setStatus(ConnStatus s, {String? device}) {
    status = s; if (device != null) deviceName = device; notifyListeners();
  }
  void log(String line) {
    final t = DateTime.now();
    final ts = '[${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}]';
    logs.insert(0, '$ts $line');
    if (logs.length > 60) logs.removeLast();
    notifyListeners();
  }
}

class HudEditModel extends ChangeNotifier {
  bool editMode = false;
  String? selectedId;

  void toggle()          { editMode = !editMode; selectedId = null; notifyListeners(); }
  void select(String? id){ selectedId = id; notifyListeners(); }
}

class VisualModel extends ChangeNotifier {
  double opacity       = 0.85;
  double glowIntensity = 0.42;
  double hudScale      = 1.15;
  int    accentIndex   = 0;
  bool   highFidelity  = false;
  bool   brutalistGrid = false;
  bool   dynamicScale  = false;
  bool   useOrbitron   = true;

  static const List<Color> accents = [
    Color(0xFFFF4655), Color(0xFF00E6C3),
    Color(0xFFFFD700), Color(0xFFFFFFFF), Color(0xFF4CAF50),
  ];

  Color get accent => accents[accentIndex];

  void reset() {
    opacity=0.85; glowIntensity=0.42; hudScale=1.15;
    accentIndex=0; highFidelity=false; brutalistGrid=false;
    dynamicScale=false; useOrbitron=true; notifyListeners();
  }
}

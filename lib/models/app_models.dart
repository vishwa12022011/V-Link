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
  final bool isHold;
  final bool isToggle;

  const KeyBinding({
    required this.id,
    required this.label,
    required this.keySequence,
    required this.icon,
    this.isHold = false,
    this.isToggle = false,
  });

  factory KeyBinding.fromJson(Map<String, dynamic> j) => KeyBinding(
        id: j['id'],
        label: j['label'],
        keySequence: j['keySequence'],
        icon: j['icon'],
        isHold: j['isHold'] as bool? ?? false,
        isToggle: j['isToggle'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'keySequence': keySequence,
        'icon': icon,
        'isHold': isHold,
        'isToggle': isToggle,
      };

  KeyBinding copyWith({
    String? keySequence,
    String? label,
    bool? isHold,
    bool? isToggle,
  }) =>
      KeyBinding(
        id: id,
        icon: icon,
        label: label ?? this.label,
        keySequence: keySequence ?? this.keySequence,
        isHold: isHold ?? this.isHold,
        isToggle: isToggle ?? this.isToggle,
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
    required this.id,
    required this.bindId,
    required this.x,
    required this.y,
    required this.size,
    this.opacity = 0.85,
    this.visible = true,
  });

  factory HudBtn.fromJson(Map<String, dynamic> j) => HudBtn(
        id: j['id'],
        bindId: j['bindId'],
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        size: (j['size'] as num).toDouble(),
        opacity: (j['opacity'] as num?)?.toDouble() ?? 0.85,
        visible: j['visible'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bindId': bindId,
        'x': x,
        'y': y,
        'size': size,
        'opacity': opacity,
        'visible': visible,
      };

  HudBtn clone() => HudBtn(
        id: id,
        bindId: bindId,
        x: x,
        y: y,
        size: size,
        opacity: opacity,
        visible: visible,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// HUD PROFILE
// ══════════════════════════════════════════════════════════════════════════════
class HudProfile {
  String id, name, tag;
  int latencyMs;
  String accentHex;
  double hudOpacity, hudScale, sensitivityScale;
  List<KeyBinding> bindings;
  List<HudBtn> buttons;
  DateTime updatedAt;

  HudProfile({
    required this.id,
    required this.name,
    required this.tag,
    required this.latencyMs,
    required this.accentHex,
    required this.bindings,
    required this.buttons,
    required this.updatedAt,
    this.hudOpacity = 0.85,
    this.hudScale = 1.0,
    this.sensitivityScale = 1.8,
  });

  Color get accentColor {
    try {
      return Color(int.parse('FF${accentHex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFFF4655);
    }
  }

  factory HudProfile.fromJson(Map<String, dynamic> j) => HudProfile(
        id: j['id'],
        name: j['name'],
        tag: j['tag'] ?? 'ESP32',
        latencyMs: j['latencyMs'] as int? ?? 1,
        accentHex: j['accentHex'] ?? '#FF4655',
        hudOpacity: (j['hudOpacity'] as num?)?.toDouble() ?? 0.85,
        hudScale: (j['hudScale'] as num?)?.toDouble() ?? 1.0,
        sensitivityScale: (j['sensitivityScale'] as num?)?.toDouble() ?? 1.8,
        bindings:
            (j['bindings'] as List).map((e) => KeyBinding.fromJson(e)).toList(),
        buttons: (j['buttons'] as List).map((e) => HudBtn.fromJson(e)).toList(),
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tag': tag,
        'latencyMs': latencyMs,
        'accentHex': accentHex,
        'hudOpacity': hudOpacity,
        'hudScale': hudScale,
        'sensitivityScale': sensitivityScale,
        'bindings': bindings.map((b) => b.toJson()).toList(),
        'buttons': buttons.map((b) => b.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static HudProfile get defaults {
    final bindings = <KeyBinding>[
      // Movement
      const KeyBinding(
          id: 'walk', label: 'Walk', keySequence: 'WASD', icon: 'joystick'),
      const KeyBinding(
          id: 'sprint',
          label: 'Sprint',
          keySequence: 'L-SHIFT',
          icon: 'sprint',
          isHold: true,
          isToggle: true),
      const KeyBinding(
          id: 'jump', label: 'Jump', keySequence: 'SPACE', icon: 'jump'),
      const KeyBinding(
          id: 'crouch', label: 'Crouch', keySequence: 'L-CTRL', icon: 'crouch'),
      const KeyBinding(
          id: 'slide', label: 'Slide', keySequence: 'C', icon: 'slide'),
      // Abilities — now 4 total (Q, E, X + new C/Z slot)
      const KeyBinding(
          id: 'ability1',
          label: 'Ability 1',
          keySequence: 'E',
          icon: 'ability1'),
      const KeyBinding(
          id: 'ability2',
          label: 'Ability 2',
          keySequence: 'Q',
          icon: 'ability2'),
      const KeyBinding(
          id: 'ultimate',
          label: 'Ultimate',
          keySequence: 'X',
          icon: 'ultimate'),
      const KeyBinding(
          id: 'ability4',
          label: 'Ability 4',
          keySequence: 'Z',
          icon: 'ability4'),
      // Combat
      const KeyBinding(
          id: 'fire',
          label: 'Fire (Right)',
          keySequence: 'Mouse_L',
          icon: 'fire'),
      const KeyBinding(
          id: 'fire_left',
          label: 'Fire (Left)',
          keySequence: 'Mouse_L',
          icon: 'fire'),
      const KeyBinding(
          id: 'ads',
          label: 'ADS / Scope',
          keySequence: 'Mouse_R',
          icon: 'scope',
          isHold: true,
          isToggle: true),
      const KeyBinding(
          id: 'reload', label: 'Reload', keySequence: 'R', icon: 'reload'),
      const KeyBinding(
          id: 'interact',
          label: 'Interact',
          keySequence: 'F',
          icon: 'interact'), // hand reaching
      const KeyBinding(
          id: 'quick_melee',
          label: 'Quick Melee',
          keySequence: 'G',
          icon: 'quick_melee'), // punching glove
      const KeyBinding(
          id: 'buymenu',
          label: 'Buy Menu',
          keySequence: 'B',
          icon: 'shop',
          isToggle: true),
      // Utility
      const KeyBinding(
          id: 'emoji',
          label: 'Emoji',
          keySequence: 'T',
          icon: 'emoji',
          isToggle: true),
      const KeyBinding(
          id: 'map', label: 'Map Marker', keySequence: 'M', icon: 'mappin'),
      const KeyBinding(
          id: 'mic',
          label: 'Mic',
          keySequence: 'V',
          icon: 'mic',
          isToggle: true),
      const KeyBinding(
          id: 'speaker',
          label: 'Speaker',
          keySequence: 'U',
          icon: 'speaker',
          isToggle: true),
      const KeyBinding(
          id: 'settings',
          label: 'Settings',
          keySequence: 'ESC',
          icon: 'settings'),
      const KeyBinding(
          id: 'chat', label: 'Chat', keySequence: 'ENTER', icon: 'chat'),
      const KeyBinding(
          id: 'scoreboard',
          label: 'Scoreboard',
          keySequence: 'TAB',
          icon: 'scoreboard'),
      // Weapon slots
      const KeyBinding(
          id: 'slot_primary',
          label: 'Primary (AK47)',
          keySequence: '1',
          icon: 'primary'),
      const KeyBinding(
          id: 'slot_pistol',
          label: 'Pistol (Desert Eagle)',
          keySequence: '2',
          icon: 'pistol'),
      const KeyBinding(
          id: 'slot_grenade',
          label: 'Grenade',
          keySequence: '4',
          icon: 'grenade'),
      const KeyBinding(
          id: 'slot_knife',
          label: 'Knife (Melee)',
          keySequence: '3',
          icon: 'knife'),
    ];

    final buttons = [
      // Left side
      HudBtn(id: 'b_walk', bindId: 'walk', x: 0.12, y: 0.65, size: 0.175),
      HudBtn(id: 'b_sprint', bindId: 'sprint', x: 0.27, y: 0.76, size: 0.082),
      HudBtn(id: 'b_mic', bindId: 'mic', x: 0.04, y: 0.90, size: 0.058),
      HudBtn(id: 'b_speaker', bindId: 'speaker', x: 0.11, y: 0.90, size: 0.058),
      HudBtn(
          id: 'b_scoreboard',
          bindId: 'scoreboard',
          x: 0.10,
          y: 0.14,
          size: 0.072),
      // Top utilities
      HudBtn(id: 'b_emoji', bindId: 'emoji', x: 0.68, y: 0.07, size: 0.058),
      HudBtn(
          id: 'b_settings', bindId: 'settings', x: 0.76, y: 0.07, size: 0.058),
      HudBtn(id: 'b_chat', bindId: 'chat', x: 0.68, y: 0.18, size: 0.058),
      HudBtn(id: 'b_mappin', bindId: 'map', x: 0.76, y: 0.18, size: 0.058),
      // Abilities — 4 buttons (Q, E, X, Z) in a 2×2 cluster top-right
      HudBtn(
          id: 'b_ability1',
          bindId: 'ability1',
          x: 0.82,
          y: 0.18,
          size: 0.088), // E
      HudBtn(
          id: 'b_ability2',
          bindId: 'ability2',
          x: 0.91,
          y: 0.18,
          size: 0.082), // Q
      HudBtn(
          id: 'b_ultimate',
          bindId: 'ultimate',
          x: 0.82,
          y: 0.32,
          size: 0.080), // X
      HudBtn(
          id: 'b_ability4',
          bindId: 'ability4',
          x: 0.91,
          y: 0.32,
          size: 0.076), // Z — new
      // Actions
      HudBtn(
          id: 'b_interact',
          bindId: 'interact',
          x: 0.97,
          y: 0.20,
          size: 0.075), // hand icon
      HudBtn(
          id: 'b_quick_melee',
          bindId: 'quick_melee',
          x: 0.97,
          y: 0.34,
          size: 0.072), // glove icon
      HudBtn(id: 'b_jump', bindId: 'jump', x: 0.63, y: 0.33, size: 0.082),
      HudBtn(id: 'b_crouch', bindId: 'crouch', x: 0.60, y: 0.60, size: 0.082),
      HudBtn(id: 'b_slide', bindId: 'slide', x: 0.70, y: 0.75, size: 0.072),
      HudBtn(id: 'b_reload', bindId: 'reload', x: 0.53, y: 0.50, size: 0.076),
      // Right combat
      HudBtn(id: 'b_ads', bindId: 'ads', x: 0.88, y: 0.38, size: 0.090),
      HudBtn(id: 'b_fire', bindId: 'fire', x: 0.88, y: 0.62, size: 0.115),
      HudBtn(
          id: 'b_fire_left',
          bindId: 'fire_left',
          x: 0.35,
          y: 0.76,
          size: 0.090),
      HudBtn(id: 'b_buymenu', bindId: 'buymenu', x: 0.97, y: 0.55, size: 0.068),
    ];

    return HudProfile(
      id: const Uuid().v4(),
      name: 'VALORANT_PRO_V1',
      tag: 'ESP32-S3-HID',
      latencyMs: 1,
      accentHex: '#FF4655',
      hudOpacity: 0.85,
      hudScale: 1.0,
      sensitivityScale: 1.8,
      bindings: bindings,
      buttons: buttons,
      updatedAt: DateTime.now(),
    );
  }

  String timeAgo() {
    final d = DateTime.now().difference(updatedAt);
    if (d.inMinutes < 60) return '${d.inMinutes}M AGO';
    if (d.inHours < 24) return '${d.inHours}H AGO';
    return '${d.inDays}D AGO';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEAPON MODELS
// ══════════════════════════════════════════════════════════════════════════════
enum WeaponType { primary, pistol, grenade, knife }

class WeaponDef {
  final String id, name, slotLabel;
  final WeaponType type;
  String keySequence;

  WeaponDef({
    required this.id,
    required this.name,
    required this.slotLabel,
    required this.type,
    required this.keySequence,
  });

  WeaponDef copyWith({String? keySequence}) => WeaponDef(
        id: id,
        name: name,
        slotLabel: slotLabel,
        type: type,
        keySequence: keySequence ?? this.keySequence,
      );
}

class WeaponSlotModel extends ChangeNotifier {
  late List<WeaponDef> _weapons;
  int _activeIndex = 0;
  Color accentColor = const Color(0xFFFF4655);

  WeaponSlotModel() {
    _weapons = _defaults();
  }

  static List<WeaponDef> _defaults() => [
        WeaponDef(
            id: 'primary',
            name: 'AK-47',
            slotLabel: 'Primary',
            type: WeaponType.primary,
            keySequence: '1'),
        WeaponDef(
            id: 'pistol',
            name: 'Desert Eagle',
            slotLabel: 'Pistol',
            type: WeaponType.pistol,
            keySequence: '2'),
        WeaponDef(
            id: 'grenade',
            name: 'Grenade',
            slotLabel: 'Throwable',
            type: WeaponType.grenade,
            keySequence: '4'),
        WeaponDef(
            id: 'knife',
            name: 'Knife',
            slotLabel: 'Melee',
            type: WeaponType.knife,
            keySequence: '3'),
      ];

  WeaponDef get activeWeapon => _weapons[_activeIndex];
  List<WeaponDef> get inactiveWeapons => [
        for (int i = 0; i < _weapons.length; i++)
          if (i != _activeIndex) _weapons[i],
      ];

  void activateById(String id) {
    final idx = _weapons.indexWhere((w) => w.id == id);
    if (idx < 0 || idx == _activeIndex) return;
    _activeIndex = idx;
    notifyListeners();
  }

  void remapWeapon(String wid, String key) {
    final i = _weapons.indexWhere((w) => w.id == wid);
    if (i >= 0) {
      _weapons[i] = _weapons[i].copyWith(keySequence: key);
      notifyListeners();
    }
  }

  void setAccent(Color c) {
    accentColor = c;
    notifyListeners();
  }

  void syncFromBindings(List<KeyBinding> bindings) {
    const m = {
      'slot_primary': 'primary',
      'slot_pistol': 'pistol',
      'slot_grenade': 'grenade',
      'slot_knife': 'knife'
    };
    for (final b in bindings) {
      final w = m[b.id];
      if (w != null) remapWeapon(w, b.keySequence);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATE MODELS
// ══════════════════════════════════════════════════════════════════════════════
class ToggleStateModel extends ChangeNotifier {
  final Map<String, bool> _s = {};
  bool isOn(String id) => _s[id] ?? false;
  bool flip(String id) {
    _s[id] = !(_s[id] ?? false);
    notifyListeners();
    return _s[id]!;
  }

  void setOff(String id) {
    if (_s[id] == true) {
      _s[id] = false;
      notifyListeners();
    }
  }

  void reset() {
    _s.clear();
    notifyListeners();
  }
}

enum Transport { ble, wifi }

enum ConnStatus { disconnected, scanning, connecting, connected }

class ConnModel extends ChangeNotifier {
  Transport mode = Transport.ble;
  ConnStatus status = ConnStatus.disconnected;
  String? deviceName;
  int latencyMs = 0;
  final List<String> logs = [];
  bool get isConnected => status == ConnStatus.connected;
  void setMode(Transport m) {
    mode = m;
    notifyListeners();
  }

  void setStatus(ConnStatus s, {String? device}) {
    status = s;
    if (device != null) deviceName = device;
    notifyListeners();
  }

  void log(String line) {
    final t = DateTime.now();
    final ts =
        '[${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}]';
    logs.insert(0, '$ts $line');
    if (logs.length > 60) logs.removeLast();
    notifyListeners();
  }
}

class HudEditModel extends ChangeNotifier {
  bool editMode = false;
  String? selectedId;
  void enterEdit() {
    editMode = true;
    selectedId = null;
    notifyListeners();
  }

  void exitEdit() {
    editMode = false;
    selectedId = null;
    notifyListeners();
  }

  void select(String? id) {
    selectedId = id;
    notifyListeners();
  }
}

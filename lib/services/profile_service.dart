import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class ProfileService extends ChangeNotifier {
  static const _listKey   = 'vlink_profiles_v2';
  static const _activeKey = 'vlink_active_v2';

  List<HudProfile> profiles = [];
  HudProfile? active;

  ProfileService() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_listKey);
    final actId = prefs.getString(_activeKey);
    if (raw != null) {
      profiles = (jsonDecode(raw) as List).map((e) => HudProfile.fromJson(e)).toList();
    }
    if (profiles.isEmpty) { profiles.add(HudProfile.defaults); await _save(); }
    active = actId != null
        ? profiles.firstWhere((p) => p.id == actId, orElse: () => profiles.first)
        : profiles.first;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, jsonEncode(profiles.map((p) => p.toJson()).toList()));
    if (active != null) await prefs.setString(_activeKey, active!.id);
  }

  Future<void> save(HudProfile p) async {
    p.updatedAt = DateTime.now();
    final i = profiles.indexWhere((x) => x.id == p.id);
    if (i >= 0) profiles[i] = p; else profiles.add(p);
    await _save(); notifyListeners();
  }

  Future<void> setActive(HudProfile p) async {
    active = p; await _save(); notifyListeners();
  }

  Future<void> delete(String id) async {
    profiles.removeWhere((p) => p.id == id);
    if (active?.id == id) active = profiles.isNotEmpty ? profiles.first : null;
    await _save(); notifyListeners();
  }

  void updateBtn(HudBtn updated) {
    if (active == null) return;
    final i = active!.buttons.indexWhere((b) => b.id == updated.id);
    if (i >= 0) { active!.buttons[i] = updated; notifyListeners(); }
  }

  void updateBinding(HudProfile profile, KeyBinding updated) {
    profile.bindings.forEach((key, value) {
      final i = value.indexWhere((b) => b.id == updated.id);
      if (i >= 0) {
        value[i] = updated;
      }
    });
  }

  Future<void> resetToDefaults(HudProfile profile) async {
    // Fixed: Uses copyWith() on the KeyBinding model to clone deep objects securely
    final defaultBindings = Map<String, List<KeyBinding>>.from(
      HudProfile.defaults.bindings.map(
        (key, value) => MapEntry(
          key,
          value.map((binding) => binding.copyWith(
            label: binding.label,
            keySequence: binding.keySequence,
            isHold: binding.isHold,
            isToggle: binding.isToggle,
          )).toList(),
        ),
      ),
    );
    final defaultButtons = HudProfile.defaults.buttons.map((b) => b.clone()).toList();

    profile.bindings = defaultBindings;
    profile.buttons = defaultButtons;
    await save(profile);
  }
}
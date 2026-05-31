import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlink/models/app_models.dart';
import 'package:vlink/services/profile_service.dart';
import 'package:vlink/utils/app_theme.dart';
import 'package:vlink/widgets/key_binding_row.dart';
import 'package:vlink/widgets/v_header.dart';

class BindingsScreen extends StatefulWidget {
  const BindingsScreen({super.key});

  @override
  State<BindingsScreen> createState() => _BindingsScreenState();
}

class _BindingsScreenState extends State<BindingsScreen> {
  HudProfile? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<ProfileService>();
    final profile = _selectedProfile ??
        ps.profiles.firstWhere((p) => p.name == 'V-LINK', orElse: () => ps.profiles.first);

    final sections = [
      ('MOVEMENT', ['walk', 'sprint', 'jump', 'crouch', 'slide']),
      ('ABILITIES', ['ability1', 'ability2', 'ultimate', 'ability3', 'ability4']),
      ('COMBAT', ['fire', 'fire_left', 'ads', 'reload', 'quick_melee']),
      ('INTERACTION', ['interact', 'buymenu']),
      ('COMMUNICATION', ['mic', 'speaker', 'chat', 'emoji', 'settings', 'scoreboard', 'map']),
      ('WEAPON SLOTS', ['slot_primary', 'slot_pistol', 'slot_grenade', 'slot_knife']),
    ];

    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: VHeader(
          title: 'BINDINGS',
          sub: profile.name,
          trailing: _profileSelector(ps.profiles),
        )),
        SliverToBoxAdapter(
            child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: T.bg2,
            border: Border(left: BorderSide(color: T.red, width: 3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: T.grey, size: 15),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              'Tap any row to remap. Use + to build combos. ',
              style: T.mono(9, color: T.grey),
            )),
          ]),
        )),
        ...sections.map((sec) {
          final sectionBindings = profile.bindings.values
              .expand((b) => b)
              .where((b) => sec.$2.contains(b.id))
              .toList();
          if (sectionBindings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverToBoxAdapter(
              child: _Section(
            title: sec.$1,
            bindings: sectionBindings,
            onUpdate: (updated) async {
              ps.updateBinding(profile, updated);
              await ps.save(profile);
            },
          ));
        }),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ]),
      bottomSheet: _SaveBar(profile: profile),
    );
  }

  Widget _profileSelector(List<HudProfile> profiles) => DropdownButton<HudProfile>(
        value: _selectedProfile ?? profiles.first,
        dropdownColor: T.bg2,
        focusColor: Colors.transparent,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: T.red, size: 18),
        onChanged: (HudProfile? newValue) {
          setState(() {
            _selectedProfile = newValue!;
          });
        },
        items: profiles.map<DropdownMenuItem<HudProfile>>((HudProfile value) {
          return DropdownMenuItem<HudProfile>(
            value: value,
            child: Text(value.name, style: T.raj(14)),
          );
        }).toList(),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<KeyBinding> bindings;
  final Future<void> Function(KeyBinding) onUpdate;

  const _Section({
    required this.title,
    required this.bindings,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Row(children: [
              Container(width: 3, height: 12, color: T.red),
              const SizedBox(width: 8),
              Text(title, style: T.mono(9, color: T.grey).copyWith(letterSpacing: 2)),
            ]),
          ),
          ...bindings.map((b) => KeyBindingRow(binding: b, onUpdate: onUpdate)),
        ],
      );
}

class _SaveBar extends StatelessWidget {
  final HudProfile profile;
  const _SaveBar({required this.profile});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: T.bg1,
          border: Border(top: BorderSide(color: T.border)),
        ),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
            onTap: () => context.read<ProfileService>().save(profile),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: T.red,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.save, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('SAVE PROFILE', style: T.raj(14)),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              context.read<ProfileService>().resetToDefaults(profile);
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.border)),
              child: const Icon(Icons.refresh, color: T.grey, size: 20),
            ),
          ),
        ]),
      );
}

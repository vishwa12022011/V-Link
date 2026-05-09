import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../services/profile_service.dart';
import '../utils/app_theme.dart';
import '../widgets/key_binding_row.dart';

class BindingsScreen extends StatelessWidget {
  const BindingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ps      = context.watch<ProfileService>();
    final profile = ps.active;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator(color: T.red));
    }

    // All sections — ability4, quick_melee, slide all included
    final sections = [
<<<<<<< Updated upstream
      ('MOVEMENT & CORE',     ['walk','sprint','jump','crouch']),
      ('ABILITIES & COMBAT',  ['ability1','ability2','ultimate','fire','ads']),
      ('UTILITY',             ['reload','buymenu','interact','gunswitch','knife','throw','emoji','map']),
      ('COMMUNICATION',       ['mic','speaker','chat','settings','scoreboard']),
=======
      ('MOVEMENT',        ['walk','sprint','jump','crouch','slide']),
      ('ABILITIES',       ['ability1','ability2','ultimate','ability4']),
      ('COMBAT',          ['fire','fire_left','ads','reload','quick_melee']),
      ('INTERACTION',     ['interact','buymenu']),
      ('COMMUNICATION',   ['mic','speaker','chat','emoji','settings','scoreboard','map']),
      ('WEAPON SLOTS',    ['slot_primary','slot_pistol','slot_grenade','slot_knife']),
>>>>>>> Stashed changes
    ];

    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [
<<<<<<< Updated upstream
        SliverToBoxAdapter(child: VHeader(
          title: 'BINDINGS / ${profile.name.split("_").first}',
          sub: 'V-01',
          trailing: VPill(label: 'ESP32: CONNECTED', color: T.teal),
        )),

        ...sections.map((sec) => SliverToBoxAdapter(child: _Section(
          title: sec.$1,
          bindings: profile.bindings.where((b) => sec.$2.contains(b.id)).toList(),
          onUpdate: (updated) async {
            ps.updateBinding(updated);
            await ps.save(profile);
          },
        ))),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
=======

        // Header
        SliverToBoxAdapter(child: VHeader(
          title: 'BINDINGS',
          sub: profile.name,
          trailing: VPill(label: 'ESP32: READY', color: T.teal),
        )),

        // Info hint
        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: T.bg2,
            border: Border(left: BorderSide(color: T.red, width: 3)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: T.grey, size: 15),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Tap any row to remap. Use + to build combos. '
              'Enable HOLD to keep the key pressed while toggled.',
              style: T.mono(9, color: T.grey),
            )),
          ]),
        )),

        // Sections
        ...sections.map((sec) {
          final sectionBindings = profile.bindings
              .where((b) => sec.$2.contains(b.id))
              .toList();
          if (sectionBindings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverToBoxAdapter(child: _Section(
            title: sec.$1,
            bindings: sectionBindings,
            onUpdate: (updated) async {
              ps.updateBinding(updated);
              await ps.save(profile);
            },
          ));
        }),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
>>>>>>> Stashed changes
      ]),
      bottomSheet: _SaveBar(profile: profile),
    );
  }
}

<<<<<<< Updated upstream
=======
// ── Section widget ────────────────────────────────────────────────────────────
>>>>>>> Stashed changes
class _Section extends StatelessWidget {
  final String title;
  final List<KeyBinding> bindings;
  final Future<void> Function(KeyBinding) onUpdate;
  const _Section({required this.title, required this.bindings, required this.onUpdate});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(title, style: T.mono(9, color: T.grey).copyWith(letterSpacing: 2)),
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
      Expanded(child: GestureDetector(
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
<<<<<<< Updated upstream
        onTap: () {},
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: T.bg2, border: Border.all(color: T.border)),
=======
        onTap: () {
          final defaults = HudProfile.defaults.bindings;
          for (final b in defaults) {
            context.read<ProfileService>().updateBinding(b);
          }
        },
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: T.bg2, border: Border.all(color: T.border)),
>>>>>>> Stashed changes
          child: const Icon(Icons.refresh, color: T.grey, size: 20),
        ),
      ),
    ]),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vlink/models/app_models.dart';
import 'package:vlink/services/profile_service.dart';
import 'package:vlink/utils/app_theme.dart';
import 'package:vlink/widgets/v_header.dart';
import 'controller_screen.dart';

class ProfileVaultScreen extends StatefulWidget {
  const ProfileVaultScreen({super.key});

  @override
  State<ProfileVaultScreen> createState() => _ProfileVaultScreenState();
}

class _ProfileVaultScreenState extends State<ProfileVaultScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<ProfileService>();
    final profiles = ps.profiles
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: T.bg0,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: VHeader(
          title: 'PROFILE_VAULT',
          sub: 'ENCRYPTED CONFIGURATION STORAGE',
          trailing: _stats(ps),
        )),
        SliverToBoxAdapter(
            child: _SearchAdd(
          onAdd: () => _addProfile(context, ps),
          onSearchChanged: (q) => setState(() => _searchQuery = q),
        )),
        SliverList(
            delegate: SliverChildBuilderDelegate(
          (_, i) => _ProfileCard(
            profile: profiles[i],
            isActive: ps.active?.id == profiles[i].id,
            onDeploy: () {
              ps.setActive(profiles[i]);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ControllerScreen(profile: profiles[i]),
              ));
            },
            onDelete: () => ps.delete(profiles[i].id),
            onRename: () => _showRenameDialog(context, ps, profiles[i]),
          ),
          childCount: profiles.length,
        )),
        SliverToBoxAdapter(child: _SyncBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  Widget _stats(ProfileService ps) => Row(children: [
        _Stat('TOTAL', '${ps.profiles.length}'),
        const SizedBox(width: 20),
        _Stat('SYNCED', '${ps.profiles.length}'),
        const SizedBox(width: 20),
        const _Stat('CLOUD', '0'),
      ]);

  void _addProfile(BuildContext ctx, ProfileService ps) {
    final vLinkProfiles =
        ps.profiles.where((p) => p.name.startsWith('V-LINK')).toList();
    final nextNum = (vLinkProfiles.isEmpty)
        ? 1
        : vLinkProfiles
                .map((p) => int.tryParse(p.name.replaceAll('V-LINK', '')) ?? 0)
                .fold(0, (max, e) => e > max ? e : max) +
            1;
    final name = (nextNum == 1) ? 'V-LINK' : 'V-LINK$nextNum';

    final p = HudProfile(
      id: const Uuid().v4(),
      name: name,
      tag: 'ESP32',
      latencyMs: 2,
      accentHex: '#FF4655',
      bindings: HudProfile.defaults.bindings,
      buttons: HudProfile.defaults.buttons,
      updatedAt: DateTime.now(),
    );
    ps.save(p);
  }

  void _showRenameDialog(
      BuildContext context, ProfileService ps, HudProfile profile) {
    final controller = TextEditingController(text: profile.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: T.bg2,
        title: Text('Rename Profile', style: T.orb(16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: T.raj(14),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: T.mono(12, color: T.greyDim),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: T.red)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL', style: T.mono(11, color: T.grey)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                profile.name = newName;
                ps.save(profile);
                Navigator.of(context).pop();
              }
            },
            child: Text('SAVE', style: T.mono(11, color: T.red)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.mono(8, color: T.greyDim)),
          Text(value, style: T.orb(18)),
        ],
      );
}

class _SearchAdd extends StatelessWidget {
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchChanged;
  const _SearchAdd({required this.onAdd, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                color: T.bg2, border: Border.all(color: T.border)),
            child: TextField(
              onChanged: onSearchChanged,
              style: T.raj(14),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: InputBorder.none,
                hintText: 'SEARCH_REGISTRY…',
                hintStyle: T.mono(10, color: T.greyDim),
                prefixIcon:
                    const Icon(Icons.search, color: T.greyDim, size: 18),
              ),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAdd,
            child: Container(
                width: 44,
                height: 44,
                color: T.red,
                child: const Icon(Icons.add, color: Colors.white, size: 22)),
          ),
        ]),
      );
}

class _ProfileCard extends StatelessWidget {
  final HudProfile profile;
  final bool isActive;
  final VoidCallback onDeploy, onDelete, onRename;
  const _ProfileCard(
      {required this.profile,
      required this.isActive,
      required this.onDeploy,
      required this.onDelete,
      required this.onRename});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: T.panel(active: isActive),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(profile.name, style: T.orb(13)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? T.red : T.greyDim)),
                    const SizedBox(width: 5),
                    Text(profile.tag, style: T.mono(9)),
                  ]),
                ])),
            if (isActive) const VPill(label: 'ACTIVE', color: T.teal),
          ]),
        ),

        // Stats row
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          color: T.bg3,
          child: Row(children: [
            // Pixel art preview
            _PixelPreview(seed: profile.id.hashCode),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MAPS: ${profile.bindings.length} KEYS',
                  style: T.mono(10, color: T.grey)),
              const SizedBox(height: 4),
              Text('LATENCY: ${profile.latencyMs}ms',
                  style: T.mono(10, color: T.grey)),
              const SizedBox(height: 4),
              Text('UPDATED: ${profile.timeAgo()}',
                  style: T.mono(9, color: T.greyDim)),
            ]),
          ]),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            _ico(Icons.share, () {}),
            const SizedBox(width: 14),
            _ico(Icons.edit_outlined, onRename),
            const SizedBox(width: 14),
            _ico(Icons.delete_outline, onDelete),
            const Spacer(),
            GestureDetector(
              onTap: onDeploy,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: T.red,
                child: Row(children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('DEPLOY', style: T.mono(10, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _ico(IconData i, VoidCallback t) => GestureDetector(
        onTap: t,
        child: Icon(i, color: T.grey, size: 18),
      );
}

class _PixelPreview extends StatelessWidget {
  final int seed;
  const _PixelPreview({required this.seed});

  @override
  Widget build(BuildContext context) {
    final palette = [
      T.bg0,
      T.red.withValues(alpha: 0.6),
      T.teal.withValues(alpha: 0.4),
      T.bg3
    ];
    return SizedBox(
      width: 52,
      height: 52,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
        itemCount: 36,
        itemBuilder: (_, i) => Container(
          color: palette[((seed * (i + 1) * 7) % palette.length).abs()],
        ),
      ),
    );
  }
}

class _SyncBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: T.bg2,
          border: Border.all(color: T.teal.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_sync, color: T.teal, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text('VAULT SYNCHRONIZED', style: T.mono(10, color: T.teal))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: T.tealDim,
            child: Text('BACKUP ALL', style: T.mono(9, color: T.teal)),
          ),
        ]),
      );
}

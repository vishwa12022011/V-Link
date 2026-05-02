import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// WEAPON SLOT BAR
// Layout matches the uploaded screenshot:
//   ┌─────────────────────────────┐
//   │  BIG BOX  (active weapon)   │
//   └─────────────────────────────┘
//   [ slot1 ][ slot2 ][ slot3 ][ slot4 ]   ← bottom row (inactive)
//
// Tapping a bottom slot promotes it to the big box.
// The previously active weapon moves to that slot position.
// Sends the correct key to PC on every slot tap.
// ══════════════════════════════════════════════════════════════════════════════

class WeaponSlotBar extends StatelessWidget {
  final WeaponSlotModel model;
  final void Function(String key) onKeyTap;
  final bool editMode;

  const WeaponSlotBar({
    super.key,
    required this.model,
    required this.onKeyTap,
    this.editMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final active   = model.activeWeapon;
    final inactive = model.inactiveWeapons;
    final accent   = model.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1117),
        border: Border.all(
          color: editMode
              ? const Color(0xFF00E6C3)
              : const Color(0x33FFFFFF),
          width: editMode ? 1.5 : 1,
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // ── Big active weapon box ───────────────────────────────────────
        _BigSlot(
          weapon:   active,
          accent:   accent,
          editMode: editMode,
        ),

        // Thin divider
        Container(height: 1, color: const Color(0x22FFFFFF)),

        // ── Bottom inactive row ─────────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: inactive.asMap().entries.map((e) {
            final idx    = e.key;
            final weapon = e.value;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              if (idx > 0)
                Container(width: 1, height: 52, color: const Color(0x22FFFFFF)),
              _SmallSlot(
                weapon:   weapon,
                accent:   accent,
                editMode: editMode,
                onTap: () {
                  if (!editMode) {
                    model.activateById(weapon.id);
                    onKeyTap(weapon.keySequence);
                  }
                },
              ),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BIG SLOT  —  currently active weapon
// ══════════════════════════════════════════════════════════════════════════════
class _BigSlot extends StatelessWidget {
  final WeaponDef weapon;
  final Color     accent;
  final bool      editMode;

  const _BigSlot({
    required this.weapon,
    required this.accent,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  180,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: accent.withOpacity(0.08),
      child: Row(children: [
        // Weapon icon
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            border: Border.all(color: accent.withOpacity(0.5)),
          ),
          child: Icon(weapon.icon, color: accent, size: 22),
        ),
        const SizedBox(width: 10),
        // Name + ammo
        Expanded(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(weapon.name,
                style: T.raj(13, color: Colors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(weapon.ammo,
                  style: T.mono(10, color: accent)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                color: accent.withOpacity(0.20),
                child: Text(weapon.keySequence,
                    style: T.mono(8, color: accent)),
              ),
            ]),
          ],
        )),
        // Active indicator
        Container(
          width: 4, height: 28,
          color: accent,
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL SLOT  —  inactive weapon in bottom row
// ══════════════════════════════════════════════════════════════════════════════
class _SmallSlot extends StatefulWidget {
  final WeaponDef  weapon;
  final Color      accent;
  final bool       editMode;
  final VoidCallback onTap;

  const _SmallSlot({
    required this.weapon,
    required this.accent,
    required this.editMode,
    required this.onTap,
  });

  @override
  State<_SmallSlot> createState() => _SmallSlotState();
}

class _SmallSlotState extends State<_SmallSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.editMode) return;
        HapticFeedback.lightImpact();
        setState(() => _down = true);
        _ctrl.forward();
        widget.onTap();
      },
      onTapUp:     (_) { setState(() => _down = false); _ctrl.reverse(); },
      onTapCancel: ()  { setState(() => _down = false); _ctrl.reverse(); },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width:   56,
          height:  52,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          color:   _down
              ? widget.accent.withOpacity(0.15)
              : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.weapon.icon,
                  size:  20,
                  color: _down
                      ? widget.accent
                      : const Color(0xAAFFFFFF)),
              const SizedBox(height: 3),
              // Slot number badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _down
                      ? widget.accent
                      : const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  widget.weapon.keySequence,
                  style: T.mono(8,
                      color: _down ? Colors.white : const Color(0xAAFFFFFF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import 'weapon_silhouette_painter.dart';

/// Weapon slot bar matching the reference screenshot layout:
///
///  ┌───────────────────────────────────────────┐
///  │  [silhouette]  SLOT_LABEL        key ▌    │  ← big box (active)
///  └───────────────────────────────────────────┘
///  [ slot1 ]  [ slot2 ]  [ slot3 ]              ← bottom row (inactive, slanted)
///
/// • No ammo count shown
/// • Active weapon: horizontal, name on left, silhouette on right
/// • Inactive slots: slanted upward silhouette only
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
    final accent = model.accentColor;
    final active = model.activeWeapon;
    final inactive = model.inactiveWeapons;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Big active box ─────────────────────────────────────────────────
        _ActiveBox(weapon: active, accent: accent, editMode: editMode),
        const SizedBox(height: 3),

        // ── Inactive bottom row ────────────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: inactive
              .map((w) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: _InactiveSlot(
                      weapon: w,
                      accent: accent,
                      editMode: editMode,
                      onTap: () {
                        if (!editMode) {
                          model.activateById(w.id);
                          onKeyTap(w.keySequence);
                        }
                      },
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BIG ACTIVE BOX
// Layout: [slot label] [weapon name]  |  [silhouette]  [key badge] [accent bar]
// ══════════════════════════════════════════════════════════════════════════════
class _ActiveBox extends StatelessWidget {
  final WeaponDef weapon;
  final Color accent;
  final bool editMode;

  const _ActiveBox({
    required this.weapon,
    required this.accent,
    required this.editMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xCC0B1117),
        border: Border.all(
          color: editMode ? const Color(0xFF00E6C3) : accent.withOpacity(0.50),
          width: editMode ? 1.5 : 1.0,
        ),
      ),
      child: Row(children: [
        // Left: slot label + weapon name
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weapon.slotLabel.toUpperCase(),
                  style: T.mono(8, color: accent.withOpacity(0.70)),
                ),
                const SizedBox(height: 3),
                Text(
                  weapon.name,
                  style: T.raj(14, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Right: weapon silhouette (horizontal, facing left)
        SizedBox(
          width: 90,
          height: 62,
          child: CustomPaint(
            painter: WeaponSilhouettePainter(
              type: weapon.type,
              color: Colors.white.withOpacity(0.82),
              active: true,
            ),
          ),
        ),

        // Key badge
        Container(
          width: 26,
          margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.18),
            border: Border.all(color: accent.withOpacity(0.45)),
          ),
          child: Center(
            child: Text(
              weapon.keySequence,
              style: T.mono(9, color: accent),
            ),
          ),
        ),

        // Accent bar (right edge)
        Container(width: 4, color: accent),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INACTIVE SLOT
// Slanted upward ~30°, silhouette only, no text, tap to activate
// ══════════════════════════════════════════════════════════════════════════════
class _InactiveSlot extends StatefulWidget {
  final WeaponDef weapon;
  final Color accent;
  final bool editMode;
  final VoidCallback onTap;

  const _InactiveSlot({
    required this.weapon,
    required this.accent,
    required this.editMode,
    required this.onTap,
  });

  @override
  State<_InactiveSlot> createState() => _InactiveSlotState();
}

class _InactiveSlotState extends State<_InactiveSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
      onTapUp: (_) {
        setState(() => _down = false);
        _ctrl.reverse();
      },
      onTapCancel: () {
        setState(() => _down = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 62,
          height: 55,
          decoration: BoxDecoration(
            color: _down
                ? widget.accent.withOpacity(0.18)
                : const Color(0xBB0B1117),
            border: Border.all(
              color: widget.editMode
                  ? const Color(0xFF00E6C3)
                  : _down
                      ? widget.accent
                      : const Color(0x44FFFFFF),
              width: widget.editMode ? 1.5 : 1.0,
            ),
          ),
          child: Stack(children: [
            // Slanted silhouette (painted with rotation inside painter)
            Positioned.fill(
              child: CustomPaint(
                painter: WeaponSilhouettePainter(
                  type: widget.weapon.type,
                  color: _down ? widget.accent : Colors.white.withOpacity(0.55),
                  active: false, // slanted upward
                ),
              ),
            ),
            // Key number badge (bottom-right)
            Positioned(
              bottom: 3,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _down ? widget.accent : const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  widget.weapon.keySequence,
                  style: T.mono(8,
                      color: _down ? Colors.white : const Color(0xAAFFFFFF)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

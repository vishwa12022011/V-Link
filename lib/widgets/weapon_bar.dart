import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Bottom-centre weapon bar: pistol | primary | melee  +  ammo display
class WeaponBar extends StatelessWidget {
  final bool editMode;
  const WeaponBar({super.key, this.editMode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xBB0B1117),
        border: Border.all(
          color: editMode ? T.teal : const Color(0x44FFFFFF),
          width: editMode ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Weapon 1 – pistol
        _WeaponSlot(icon: Icons.pest_control, label: '00/00', active: false),
        // Divider
        Container(width: 1, color: const Color(0x33FFFFFF)),
        // Weapon 2 – primary (active)
        _WeaponSlot(icon: Icons.crop_16_9, label: '30/200', active: true),
        // Divider
        Container(width: 1, color: const Color(0x33FFFFFF)),
        // Weapon 3 – melee
        _WeaponSlot(icon: Icons.edit, label: '∞', active: false),
        // Ammo mode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.menu, color: const Color(0xAAFFFFFF), size: 14),
            const SizedBox(height: 2),
            Text('Continuous', style: T.mono(8, color: const Color(0x88FFFFFF))),
          ]),
        ),
      ]),
    );
  }
}

class _WeaponSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _WeaponSlot({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: active ? const Color(0x33FF4655) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Icon(icon,
              color: active ? Colors.white : const Color(0x88FFFFFF),
              size: 22),
          const SizedBox(width: 6),
          Text(label,
              style: T.raj(11, color: active ? Colors.white : const Color(0x88FFFFFF))),
        ]),
      ),
    );
  }
}

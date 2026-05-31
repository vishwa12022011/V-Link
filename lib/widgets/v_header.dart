import 'package:flutter/material.dart';
import 'package:vlink/utils/app_theme.dart';

class VHeader extends StatelessWidget {
  final String title;
  final String sub;
  final Widget? trailing;

  const VHeader({
    super.key,
    required this.title,
    required this.sub,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.border, width: 1)),
        color: Color.fromARGB(255, 27, 39, 53),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: T.orb(20)),
              const SizedBox(height: 2),
              Text(sub, style: T.mono(9, color: T.grey)),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

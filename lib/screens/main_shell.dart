import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import 'bindings_screen.dart';
import 'connectivity_screen.dart';
import 'profile_vault_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _tabs = [
    (Icons.folder_special_outlined, 'VAULT'),
    (Icons.keyboard_outlined, 'BINDINGS'),
    (Icons.bluetooth_outlined, 'CONNECT'),
  ];

  static const _screens = [
    ProfileVaultScreen(),
    BindingsScreen(),
    ConnectivityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnModel>();

    return Scaffold(
      backgroundColor: T.bg0,
      body: _screens[_tab],
      bottomNavigationBar: _NavBar(
        selected: _tab,
        onTap: (i) => setState(() => _tab = i),
        connStatus: conn.status,
        accent: const Color(0xFFFF4655),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  final ConnStatus connStatus;
  final Color accent;

  const _NavBar({
    required this.selected,
    required this.onTap,
    required this.connStatus,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final connColor = connStatus == ConnStatus.connected
        ? T.teal
        : connStatus == ConnStatus.scanning
            ? T.gold
            : T.greyDim;

    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: T.bg1,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: Row(children: [
        // Left accent bar — connection status colour
        Container(width: 3, color: connColor),

        // Tabs
        ...List.generate(_MainShellState._tabs.length, (i) {
          final sel = i == selected;
          return Expanded(
              child: GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: sel ? T.bg2 : Colors.transparent,
                border: sel
                    ? Border(top: BorderSide(color: accent, width: 2))
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_MainShellState._tabs[i].$1,
                      size: 19, color: sel ? accent : T.greyDim),
                  const SizedBox(height: 3),
                  Text(_MainShellState._tabs[i].$2,
                      style: T.mono(8, color: sel ? accent : T.greyDim)),
                ],
              ),
            ),
          ));
        }),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlink/models/app_models.dart';
import 'package:vlink/models/visual_model.dart';
import 'package:vlink/screens/bindings_screen.dart';
import 'package:vlink/screens/connectivity_screen.dart';
import 'package:vlink/screens/profile_vault_screen.dart';
import 'package:vlink/screens/visual_engine_screen.dart';
import 'package:vlink/services/ble_service.dart';
import 'package:vlink/services/hid_service.dart';
import 'package:vlink/services/profile_service.dart';
import 'package:vlink/services/webrtc_service.dart';
import 'package:vlink/services/wifi_service.dart';
import 'package:vlink/utils/app_theme.dart';

void main() {
  runApp(const VconnApp());
}

class VconnApp extends StatelessWidget {
  const VconnApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleService()),
          ChangeNotifierProvider(create: (_) => WifiService()),
          ChangeNotifierProvider(create: (_) => HidService()),
          ChangeNotifierProvider(create: (_) => WebRtcService()),
          ChangeNotifierProvider(create: (_) => ProfileService()),
          ChangeNotifierProvider(create: (_) => WeaponSlotModel()),
          ChangeNotifierProvider(create: (_) => VisualModel()),
          ChangeNotifierProvider(create: (_) => ConnModel()),
          ChangeNotifierProvider(create: (_) => HudEditModel()),
        ],
        child: MaterialApp(
          title: 'V-CONN',
          theme: T.dark,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _navIndex = 0;

  final _screens = [
    const ProfileVaultScreen(),
    const BindingsScreen(),
    const VisualEngineScreen(),
    const ConnectivityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_navIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: T.bg1,
        selectedItemColor: T.red,
        unselectedItemColor: T.grey,
        selectedLabelStyle: T.mono(8, color: T.red),
        unselectedLabelStyle: T.mono(8, color: T.grey),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle_outlined),
            label: 'PROFILES',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_input_component_outlined),
            label: 'BINDINGS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette_outlined),
            label: 'VISUALS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined),
            label: 'CONNECT',
          ),
        ],
      ),
    );
  }
}

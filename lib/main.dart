import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/app_models.dart';
import 'services/ble_service.dart';
import 'services/profile_service.dart';
import 'services/wifi_service.dart';
import 'services/hid_service.dart';
import 'services/webrtc_service.dart';
import 'screens/boot_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hide ALL system UI globally (status bar + nav bar) ─────────────────────
  // Swipe from edge to briefly reveal — exactly like Free Fire / PUBG / Roblox
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // ── Allow portrait + both landscapes ──────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ── Make bars transparent when briefly peeked ─────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:               Colors.transparent,
    navigationBarColor:           Colors.transparent,
    statusBarIconBrightness:      Brightness.light,
    navigationBarIconBrightness:  Brightness.light,
  ));

  runApp(const VLinkApp());
}

class VLinkApp extends StatelessWidget {
  const VLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnModel()),
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => WifiService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
<<<<<<< Updated upstream
        ChangeNotifierProvider(create: (_) => VisualModel()),
=======
        ChangeNotifierProvider(create: (_) => ToggleStateModel()),
        ChangeNotifierProvider(create: (_) => HudEditModel()),
        ChangeNotifierProvider(create: (_) => WeaponSlotModel()),
        ChangeNotifierProvider(create: (_) => HidService()),
        ChangeNotifierProvider(create: (_) => WebRtcService()),
>>>>>>> Stashed changes
      ],
      child: MaterialApp(
        title: 'V-LINK',
        debugShowCheckedModeBanner: false,
        theme: T.dark,
        home: const BootScreen(),
      ),
    );
  }
}

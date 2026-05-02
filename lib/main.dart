import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/app_models.dart';
import 'services/ble_service.dart';
import 'services/profile_service.dart';
import 'services/wifi_service.dart';
import 'screens/boot_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        ChangeNotifierProvider(create: (_) => ToggleStateModel()),
        ChangeNotifierProvider(create: (_) => HudEditModel()),
        ChangeNotifierProvider(create: (_) => WeaponSlotModel()),
      ],
      child: MaterialApp(
        title:                     'V-LINK',
        debugShowCheckedModeBanner: false,
        theme:                     T.dark,
        home:                      const BootScreen(),
      ),
    );
  }
}

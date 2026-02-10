import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'managers/profile_manager.dart';
import 'managers/sync_manager.dart';
import 'managers/network_manager.dart';
import 'managers/music_manager.dart';
import 'managers/battery_manager.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase removed for local sync

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);

  runApp(const JaexoApp());
}

class JaexoApp extends StatelessWidget {
  const JaexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileManager()),
        ChangeNotifierProvider(create: (_) => NetworkManager()),
        ChangeNotifierProxyProvider<ProfileManager, SyncManager>(
          create: (context) {
            final pm = Provider.of<ProfileManager>(context, listen: false);
            final sm = SyncManager(pm);
            pm.setSyncManager(sm);
            return sm;
          },
          update: (context, profileManager, syncManager) {
            profileManager.setSyncManager(syncManager!);
            return syncManager..updateProfile(profileManager);
          },
        ),
        ChangeNotifierProvider(create: (_) => MusicManager()),
        ChangeNotifierProvider(create: (_) => BatteryManager()),
      ],
      child: Consumer<ProfileManager>(
        builder: (context, profileManager, _) {
          return MaterialApp(
            title: 'JAEXO ULTIMATE',
            debugShowCheckedModeBanner: false,
            theme: JaexoTheme.getTheme(profileManager.currentTheme),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

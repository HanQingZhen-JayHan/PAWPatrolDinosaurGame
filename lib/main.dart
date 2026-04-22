import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/app.dart';
import 'package:pup_dash/constants/dev_config.dart';
import 'package:pup_dash/firebase_options.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/providers/network_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load persisted dev-mode flag before any UI reads it
  await DevConfig.load();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Parse ?room=XXXX from URL on web
  String? initialRoomCode;
  if (kIsWeb) {
    final uri = Uri.base;
    initialRoomCode = uri.queryParameters['room'];
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProxyProvider<NetworkProvider, ControllerProvider>(
          create: (context) => ControllerProvider(
            networkProvider: context.read<NetworkProvider>(),
          ),
          update: (_, network, previous) =>
              previous ?? ControllerProvider(networkProvider: network),
        ),
      ],
      child: PupDashApp(initialRoomCode: initialRoomCode),
    ),
  );
}

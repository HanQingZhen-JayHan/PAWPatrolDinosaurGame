import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:paw_patrol_runner/app.dart';
import 'package:paw_patrol_runner/providers/controller_provider.dart';
import 'package:paw_patrol_runner/providers/game_provider.dart';
import 'package:paw_patrol_runner/providers/network_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

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
      child: const PawPatrolApp(),
    ),
  );
}

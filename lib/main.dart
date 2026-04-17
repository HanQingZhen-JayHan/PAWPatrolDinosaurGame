import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/app.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/providers/network_provider.dart';

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
      child: const PupDashApp(),
    ),
  );
}

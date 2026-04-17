import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/providers/network_provider.dart';
import 'package:pup_dash/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders title', (WidgetTester tester) async {
    await tester.pumpWidget(
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
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.text('PUP DASH'), findsOneWidget);
    expect(find.text('ENDLESS RUNNER'), findsOneWidget);

    // Pump past the 2-second timer to avoid pending timer assertion
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

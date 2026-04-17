import 'package:flutter/material.dart';

import 'package:paw_patrol_runner/constants/theme.dart';
import 'package:paw_patrol_runner/screens/splash_screen.dart';

class PawPatrolApp extends StatelessWidget {
  const PawPatrolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAW Patrol Runner',
      theme: PawTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

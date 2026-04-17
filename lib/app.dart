import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/screens/splash_screen.dart';

class PupDashApp extends StatelessWidget {
  /// Optional room code passed from URL query parameter (?room=XXXX).
  final String? initialRoomCode;

  const PupDashApp({super.key, this.initialRoomCode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pup Dash',
      theme: PupTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(initialRoomCode: initialRoomCode),
    );
  }
}

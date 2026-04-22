import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/screens/controller_join_screen.dart';
import 'package:pup_dash/screens/host_lobby_screen.dart';

class PupDashApp extends StatelessWidget {
  /// Optional room code passed from URL query parameter (?room=XXXX).
  final String? initialRoomCode;

  const PupDashApp({super.key, this.initialRoomCode});

  @override
  Widget build(BuildContext context) {
    // Skip splash + mode-select. With a room code in the URL, the device
    // is a controller joining that room; otherwise it's the host and
    // lands straight on the QR-code lobby.
    final Widget home = initialRoomCode != null
        ? ControllerJoinScreen(initialRoomCode: initialRoomCode!)
        : const HostLobbyScreen();

    return MaterialApp(
      title: 'Pup Dash',
      theme: PupTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}

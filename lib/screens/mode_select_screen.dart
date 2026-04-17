import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/screens/controller_join_screen.dart';
import 'package:pup_dash/screens/host_lobby_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Web builds can only be controllers (no dart:io for WebSocket server)
    final canHost = !kIsWeb;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PupTheme.backgroundLight, PupTheme.backgroundDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, size: 64, color: PupTheme.goldStar),
              const SizedBox(height: 16),
              Text(
                'PUP DASH',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              if (canHost)
                _ModeButton(
                  icon: Icons.tv,
                  label: 'HOST GAME',
                  subtitle: 'Show game on big screen',
                  color: PupTheme.primaryBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
                  ),
                ),
              if (canHost) const SizedBox(height: 24),
              _ModeButton(
                icon: Icons.phone_android,
                label: 'JOIN GAME',
                subtitle: 'Use phone as controller',
                color: PupTheme.primaryRed,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ControllerJoinScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

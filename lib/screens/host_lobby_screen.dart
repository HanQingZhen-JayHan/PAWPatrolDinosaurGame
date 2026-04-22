import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pup_dash/constants/dev_config.dart';
import 'package:pup_dash/constants/music_config.dart';
import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/screens/game_screen.dart';
import 'package:pup_dash/widgets/character_icon.dart';
import 'package:pup_dash/widgets/dev_mode_banner.dart';

class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    provider.onPhaseChanged = (phase) {
      if (phase == GamePhase.countdown || phase == GamePhase.playing) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      }
    };
    if (!provider.isRunning) {
      provider.startServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DevModeBanner(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PupTheme.backgroundLight, PupTheme.backgroundDark],
            ),
          ),
          child: Stack(
            children: [
              Consumer<GameProvider>(
                builder: (context, provider, _) {
            if (!provider.isRunning) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Creating room...',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              );
            }

            final players = provider.state.playerList;
            final roomCode = provider.roomCode ?? '----';

            return Row(
              children: [
                // Left: Room code + QR
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ROOM CODE',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            color: PupTheme.goldStar,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            roomCode,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: PupTheme.backgroundDark,
                              letterSpacing: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                              data: 'https://hanqingzhen-jayhan.github.io/PAWPatrolDinosaurGame/?room=$roomCode',
                              size: 400),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter code or scan QR to join',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right: Player list
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PLAYERS (${players.length})',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              return Card(
                                color: player.character?.color
                                        .withValues(alpha: 0.8) ??
                                    Colors.white24,
                                child: ListTile(
                                  leading: CharacterIcon(
                                    character: player.character,
                                    size: 28,
                                  ),
                                  title: Text(
                                    player.character?.displayName ??
                                        (player.name.isEmpty
                                            ? 'Player ${index + 1}'
                                            : player.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      player.isReady
                                          ? const Icon(Icons.check_circle,
                                              color: Colors.greenAccent,
                                              size: 28)
                                          : const Text('Waiting...',
                                              style: TextStyle(
                                                  color: Colors.white70)),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white70),
                                        tooltip: 'Kick player',
                                        onPressed: () =>
                                            provider.kickPlayer(player.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (players.isEmpty)
                          const Text(
                            'Waiting for players to join...',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        if (provider.state.allReady && players.isNotEmpty)
                          const Text(
                            'All ready! Starting...',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
              ),
              // Settings buttons, bottom-right. Each toggle is persisted.
              Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Music on/off — enabled by default for kids.
                      ValueListenableBuilder<bool>(
                        valueListenable: MusicConfig.notifier,
                        builder: (context, enabled, _) {
                          return OutlinedButton.icon(
                            onPressed: () =>
                                MusicConfig.setEnabled(!enabled),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: enabled
                                  ? PupTheme.primaryBlue
                                  : Colors.black.withValues(alpha: 0.3),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: enabled
                                    ? PupTheme.primaryBlue
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            icon: Icon(
                              enabled
                                  ? Icons.music_note
                                  : Icons.music_off,
                              size: 18,
                            ),
                            label: Text(
                              enabled ? 'MUSIC: ON' : 'MUSIC: OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Dev mode toggle.
                      ValueListenableBuilder<bool>(
                        valueListenable: DevConfig.notifier,
                        builder: (context, enabled, _) {
                          return OutlinedButton.icon(
                            onPressed: () => DevConfig.setEnabled(!enabled),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: enabled
                                  ? Colors.red.shade700
                                  : Colors.black.withValues(alpha: 0.3),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: enabled
                                    ? Colors.red.shade700
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            icon: Icon(
                              enabled
                                  ? Icons.bug_report
                                  : Icons.bug_report_outlined,
                              size: 18,
                            ),
                            label: Text(
                              enabled ? 'DEV MODE: ON' : 'DEV MODE: OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

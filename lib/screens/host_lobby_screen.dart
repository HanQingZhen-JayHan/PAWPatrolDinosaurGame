import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/screens/game_screen.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PupTheme.backgroundLight, PupTheme.backgroundDark],
          ),
        ),
        child: Consumer<GameProvider>(
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
                              size: 320),
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
                                  leading: Text(
                                    player.character?.emoji ?? '❓',
                                    style: const TextStyle(fontSize: 28),
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
                                  trailing: player.isReady
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.greenAccent, size: 32)
                                      : const Text('Waiting...',
                                          style: TextStyle(
                                              color: Colors.white70)),
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
      ),
    );
  }
}

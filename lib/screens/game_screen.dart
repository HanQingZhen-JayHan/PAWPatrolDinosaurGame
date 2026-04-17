import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/game/pup_dash_game.dart';
import 'package:pup_dash/models/game_state.dart';
import 'package:pup_dash/providers/game_provider.dart';
import 'package:pup_dash/screens/host_lobby_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PupDashGame _game;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameProvider>();
    _game = PupDashGame(gameProvider: provider);

    provider.onPhaseChanged = (phase) {
      if (phase == GamePhase.lobby && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          // HUD overlay
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final state = provider.state;

              if (state.phase == GamePhase.countdown) {
                return _CountdownOverlay(value: state.countdownValue);
              }

              if (state.phase == GamePhase.gameOver) {
                return _GameOverOverlay(
                  rankings: state.rankings,
                  onPlayAgain: provider.returnToLobby,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int value;
  const _CountdownOverlay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Text(
          value > 0 ? '$value' : 'GO!',
          style: const TextStyle(
            color: PupTheme.goldStar,
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final List rankings;
  final VoidCallback onPlayAgain;

  const _GameOverOverlay({
    required this.rankings,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events,
                  size: 80, color: PupTheme.goldStar),
              const SizedBox(height: 16),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Podium: top 3
              if (rankings.isNotEmpty)
                _PodiumRow(rankings: rankings),
              const SizedBox(height: 24),
              // Full ranking list
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final player = rankings[index];
                    final emoji = player.character?.emoji ?? '🐕';
                    final name = player.character?.displayName ??
                        player.name;
                    return ListTile(
                      dense: true,
                      leading: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: index == 0
                              ? PupTheme.goldStar
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(
                        '$emoji $name',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18),
                      ),
                      trailing: Text(
                        '${player.score.toInt()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text('PLAY AGAIN',
                        style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List rankings;
  const _PodiumRow({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Show top 3 in podium order: 2nd, 1st, 3rd
    final spots = <int>[
      if (rankings.length > 1) 1,
      0,
      if (rankings.length > 2) 2,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: spots.map((i) {
        final player = rankings[i];
        final heights = [120.0, 80.0, 60.0];
        final colors = [PupTheme.goldStar, Colors.grey, Colors.brown];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.character?.emoji ?? '🐕',
                style: const TextStyle(fontSize: 36),
              ),
              Text(
                player.character?.displayName ?? player.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: 80,
                height: heights[i],
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Text(
                    '#${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

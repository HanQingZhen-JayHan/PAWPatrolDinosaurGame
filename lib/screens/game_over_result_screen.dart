import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/screens/controller_screen.dart';

class GameOverResultScreen extends StatefulWidget {
  const GameOverResultScreen({super.key});

  @override
  State<GameOverResultScreen> createState() => _GameOverResultScreenState();
}

class _GameOverResultScreenState extends State<GameOverResultScreen> {
  bool _navigatedBack = false;
  ControllerProvider? _controllerProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerProvider == null) {
      _controllerProvider = context.read<ControllerProvider>();
      _controllerProvider!.addListener(_checkForNewGame);
      // Check immediately — the state may have already changed before we subscribed
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForNewGame());
    }
  }

  void _checkForNewGame() {
    if (_navigatedBack || !mounted) return;
    final c = _controllerProvider!;
    // A new game is starting only when rankings have been cleared
    // AND a new countdown or gameplay has begun. This prevents false positives
    // from stale state that might still have gameActive=true from the previous round.
    final newGameStarted =
        c.rankings.isEmpty && (c.countdown > 0 || c.gameActive);
    if (newGameStarted) {
      _navigatedBack = true;
      final defaultCal = CalibrationResult(
        baselineY: 0,
        jumpThreshold: 2.0,
        duckThreshold: 1.0,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ControllerScreen(calibration: defaultCal),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controllerProvider?.removeListener(_checkForNewGame);
    super.dispose();
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
        child: Consumer<ControllerProvider>(
          builder: (context, controller, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy
                    const Icon(Icons.emoji_events,
                        size: 64, color: PupTheme.goldStar),
                    const SizedBox(height: 16),
                    Text(
                      'GAME OVER',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    // Personal result
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'You placed #${controller.personalRank ?? "?"}!',
                            style: const TextStyle(
                              color: PupTheme.goldStar,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Score: ${controller.personalScore.toInt()}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (controller.winnerName != null)
                      Text(
                        'Winner: ${controller.winnerName}!',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Rankings
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.rankings.length,
                        itemBuilder: (context, index) {
                          final r = controller.rankings[index];
                          final character =
                              PupCharacter.fromName(r['character'] ?? '');
                          return ListTile(
                            leading: Text(
                              '#${r['rank']}',
                              style: TextStyle(
                                color: index == 0
                                    ? PupTheme.goldStar
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Text(
                              character?.displayName ??
                                  r['playerName'] ??
                                  'Player',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                            trailing: Text(
                              '${(r['score'] as num?)?.toInt() ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Waiting for host to start next round...',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/sensor/motion_detector.dart';
import 'package:pup_dash/screens/game_over_result_screen.dart';

class ControllerScreen extends StatefulWidget {
  final CalibrationResult calibration;

  const ControllerScreen({super.key, required this.calibration});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late final MotionDetector _detector;
  bool _motionActive = false;
  String _lastAction = '';

  @override
  void initState() {
    super.initState();
    _detector = MotionDetector(calibration: widget.calibration);
    _detector.onAction = (action) {
      context.read<ControllerProvider>().sendInput(action);
      setState(() => _lastAction = action);
    };
  }

  @override
  void dispose() {
    _detector.dispose();
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
            // Navigate to results on game over
            if (controller.rankings.isNotEmpty && !controller.gameActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const GameOverResultScreen()),
                  );
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Status bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.selectedCharacter?.emoji ?? '🐕',
                          style: const TextStyle(fontSize: 40),
                        ),
                        Column(
                          children: [
                            Text(
                              'Score: ${controller.personalScore.toInt()}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: List.generate(
                                3,
                                (i) => Icon(
                                  Icons.favorite,
                                  color: i < controller.livesRemaining
                                      ? PupTheme.heartRed
                                      : Colors.white24,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Sensor status display
                    Icon(
                      _motionActive ? Icons.sensors : Icons.sensors_off,
                      size: 80,
                      color: _motionActive
                          ? Colors.greenAccent
                          : Colors.white54,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _motionActive
                          ? 'Sensors active — move to play!'
                          : 'Tap READY to start sensors',
                      style: TextStyle(
                        color: _motionActive
                            ? Colors.greenAccent
                            : Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Last detected action feedback
                    if (_motionActive && _lastAction.isNotEmpty)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _lastAction == 'jump'
                              ? Colors.green.withValues(alpha: 0.6)
                              : Colors.orange.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _lastAction.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Ready / Start / End buttons
                    if (!controller.isReady)
                      ElevatedButton(
                        onPressed: () {
                          controller.markReady();
                          _detector.start();
                          setState(() => _motionActive = true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text('READY!',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    if (controller.isReady && !controller.gameActive)
                      Column(
                        children: [
                          if (controller.countdown > 0)
                            Text(
                              '${controller.countdown}',
                              style: const TextStyle(
                                color: PupTheme.goldStar,
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: controller.requestStart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PupTheme.primaryBlue,
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: const Text('START GAME',
                                  style: TextStyle(fontSize: 20)),
                            ),
                        ],
                      ),
                    if (controller.gameActive)
                      ElevatedButton(
                        onPressed: controller.requestEnd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PupTheme.primaryRed,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text('END GAME',
                            style: TextStyle(fontSize: 20)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/models/message.dart';
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

  @override
  void initState() {
    super.initState();
    _detector = MotionDetector(calibration: widget.calibration);
    _detector.onAction = (action) {
      context.read<ControllerProvider>().sendInput(action);
    };
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  void _toggleMotion() {
    setState(() {
      if (_motionActive) {
        _detector.stop();
        _motionActive = false;
      } else {
        _detector.start();
        _motionActive = true;
      }
    });
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
                    // Motion status
                    Icon(
                      _motionActive
                          ? Icons.sensors
                          : Icons.sensors_off,
                      size: 64,
                      color: _motionActive
                          ? Colors.greenAccent
                          : Colors.white54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _motionActive
                          ? 'Motion detection ON'
                          : 'Motion detection OFF',
                      style: TextStyle(
                        color: _motionActive
                            ? Colors.greenAccent
                            : Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Toggle motion
                    ElevatedButton(
                      onPressed: _toggleMotion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _motionActive ? Colors.orange : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      child: Text(_motionActive ? 'PAUSE SENSORS' : 'START SENSORS',
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    // Fallback buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FallbackButton(
                          label: 'JUMP',
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                          onTap: () =>
                              controller.sendInput(InputAction.jump),
                        ),
                        _FallbackButton(
                          label: 'DUCK',
                          icon: Icons.arrow_downward,
                          color: Colors.orange,
                          onTapDown: () =>
                              controller.sendInput(InputAction.duckStart),
                          onTapUp: () =>
                              controller.sendInput(InputAction.duckEnd),
                        ),
                      ],
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
                                minimumSize:
                                    const Size(double.infinity, 56),
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

class _FallbackButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const _FallbackButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown != null ? (_) => onTapDown!() : null,
      onTapUp: onTapUp != null ? (_) => onTapUp!() : null,
      onTapCancel: onTapUp,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

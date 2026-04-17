import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/sensor/motion_detector.dart';
import 'package:pup_dash/screens/game_over_result_screen.dart';
import 'package:pup_dash/widgets/character_icon.dart';

@JS('requestWakeLock')
external JSPromise<JSBoolean> _jsRequestWakeLock();

@JS('releaseWakeLock')
external JSPromise<JSAny?> _jsReleaseWakeLock();

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
  bool _navigatedToResults = false;
  // Debug info
  double _rawY = 0;
  double _filteredY = 0;
  double _deviation = 0;
  bool _sensorReceiving = false;

  @override
  void initState() {
    super.initState();
    _detector = MotionDetector(calibration: widget.calibration);
    _detector.onAction = (action) {
      context.read<ControllerProvider>().sendInput(action);
      setState(() => _lastAction = action);
    };
    _detector.onDebugSample = (rawY, filteredY, deviation) {
      setState(() {
        _rawY = rawY;
        _filteredY = filteredY;
        _deviation = deviation;
        _sensorReceiving = true;
      });
    };
    // Auto-start: mark ready and begin motion detection as soon as the
    // controller screen mounts. Player doesn't need to click READY.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = context.read<ControllerProvider>();
      if (!controller.isReady) controller.markReady();
      _detector.start();
      if (mounted) setState(() => _motionActive = true);

      // On web, request a screen wake lock so the phone doesn't dim/lock
      // during gameplay — keeps the controller responsive.
      if (kIsWeb) {
        try {
          await _jsRequestWakeLock().toDart;
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _detector.dispose();
    if (kIsWeb) {
      try {
        _jsReleaseWakeLock();
      } catch (_) {}
    }
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
            // Navigate to results on game over (only once)
            if (!_navigatedToResults &&
                controller.rankings.isNotEmpty &&
                !controller.gameActive) {
              _navigatedToResults = true;
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Status bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CharacterIcon(
                            character: controller.selectedCharacter,
                            size: 36),
                        Column(
                          children: [
                            Text(
                              'Score: ${controller.personalScore.toInt()}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Sensor status
                    Icon(
                      _motionActive ? Icons.sensors : Icons.sensors_off,
                      size: 48,
                      color: _motionActive
                          ? (_sensorReceiving
                              ? Colors.greenAccent
                              : Colors.amber)
                          : Colors.white54,
                    ),
                    Text(
                      _motionActive
                          ? (_sensorReceiving
                              ? 'Sensors active'
                              : 'Waiting for sensor data...')
                          : 'Tap READY to start',
                      style: TextStyle(
                        color: _motionActive
                            ? Colors.greenAccent
                            : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Debug panel — live sensor readings
                    if (_motionActive)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _DebugRow('Raw Y', _rawY),
                            _DebugRow('Filtered Y', _filteredY),
                            _DebugRow('Deviation', _deviation),
                            _DebugRow('Jump thresh',
                                widget.calibration.jumpThreshold),
                            _DebugRow('Duck thresh',
                                widget.calibration.duckThreshold),
                            _DebugRow('Baseline',
                                widget.calibration.baselineY),
                            const SizedBox(height: 4),
                            // Visual bar showing deviation vs thresholds
                            SizedBox(
                              height: 24,
                              child: CustomPaint(
                                size: const Size(double.infinity, 24),
                                painter: _DeviationBarPainter(
                                  deviation: _deviation,
                                  jumpThreshold:
                                      widget.calibration.jumpThreshold,
                                  duckThreshold:
                                      widget.calibration.duckThreshold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Last action feedback
                    if (_lastAction.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _lastAction == 'jump'
                              ? Colors.green.withValues(alpha: 0.7)
                              : Colors.orange.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _lastAction.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Countdown while waiting for the game to begin
                    if (controller.isReady &&
                        !controller.gameActive &&
                        controller.countdown > 0)
                      Text(
                        '${controller.countdown}',
                        style: const TextStyle(
                          color: PupTheme.goldStar,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (controller.isReady &&
                        !controller.gameActive &&
                        controller.countdown == 0)
                      const Text(
                        'Waiting for other players...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    if (controller.gameActive)
                      const Text(
                        'GO! Move to play!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

class _DebugRow extends StatelessWidget {
  final String label;
  final double value;
  const _DebugRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value.toStringAsFixed(2),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _DeviationBarPainter extends CustomPainter {
  final double deviation;
  final double jumpThreshold;
  final double duckThreshold;

  _DeviationBarPainter({
    required this.deviation,
    required this.jumpThreshold,
    required this.duckThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final maxRange = (jumpThreshold * 2).clamp(5.0, 30.0);
    final scale = (size.width / 2) / maxRange;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(4)),
      Paint()..color = const Color(0x33FFFFFF),
    );

    // Jump threshold markers
    final jumpX = jumpThreshold * scale;
    canvas.drawLine(
      Offset(center + jumpX, 0),
      Offset(center + jumpX, size.height),
      Paint()
        ..color = const Color(0xFF00FF00)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(center - jumpX, 0),
      Offset(center - jumpX, size.height),
      Paint()
        ..color = const Color(0xFF00FF00)
        ..strokeWidth = 1,
    );

    // Duck threshold marker
    final duckX = duckThreshold * scale;
    canvas.drawLine(
      Offset(center - duckX, 0),
      Offset(center - duckX, size.height),
      Paint()
        ..color = const Color(0xFFFF8800)
        ..strokeWidth = 1,
    );

    // Current deviation bar
    final devX = (deviation * scale).clamp(-size.width / 2, size.width / 2);
    final barColor = deviation.abs() > jumpThreshold
        ? const Color(0xFF00FF00)
        : deviation < -duckThreshold
            ? const Color(0xFFFF8800)
            : const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(
        center,
        4,
        devX,
        size.height - 8,
      ),
      Paint()..color = barColor,
    );
  }

  @override
  bool shouldRepaint(covariant _DeviationBarPainter old) =>
      deviation != old.deviation;
}

import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/screens/controller_screen.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final MotionCalibrator _calibrator = MotionCalibrator();
  CalibrationStep _step = CalibrationStep.idle;
  double _progress = 0;
  CalibrationResult? _result;

  @override
  void initState() {
    super.initState();
    _calibrator.onProgress = (step, progress) {
      if (mounted) {
        setState(() {
          _step = step;
          _progress = progress;
        });
      }
    };
    _calibrator.onComplete = (result) {
      if (mounted) setState(() => _result = result);
    };
  }

  @override
  void dispose() {
    _calibrator.cancel();
    super.dispose();
  }

  void _startCalibration() {
    _calibrator.startCalibration();
  }

  String get _instructionText => switch (_step) {
        CalibrationStep.idle => 'Strap your phone to your body\nthen tap START',
        CalibrationStep.standStill => 'Stand still...',
        CalibrationStep.practiceJumps => 'JUMP! (${(_progress * 3).ceil()}/3)',
        CalibrationStep.practiceDuck => 'Now CROUCH down!',
        CalibrationStep.done => "You're all set! 🎉",
      };

  IconData get _instructionIcon => switch (_step) {
        CalibrationStep.idle => Icons.phone_android,
        CalibrationStep.standStill => Icons.accessibility_new,
        CalibrationStep.practiceJumps => Icons.arrow_upward,
        CalibrationStep.practiceDuck => Icons.arrow_downward,
        CalibrationStep.done => Icons.check_circle,
      };

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_instructionIcon, size: 80, color: PupTheme.goldStar),
                const SizedBox(height: 24),
                Text(
                  _instructionText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                if (_step != CalibrationStep.idle &&
                    _step != CalibrationStep.done)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    color: PupTheme.goldStar,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                const SizedBox(height: 32),
                if (_step == CalibrationStep.idle)
                  ElevatedButton(
                    onPressed: _startCalibration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PupTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                    ),
                    child: const Text('START CALIBRATION',
                        style: TextStyle(fontSize: 20)),
                  ),
                if (_result != null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              ControllerScreen(calibration: _result!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                    ),
                    child: const Text("LET'S GO!",
                        style: TextStyle(fontSize: 20)),
                  ),
                const SizedBox(height: 16),
                // Skip calibration option
                TextButton(
                  onPressed: () {
                    final defaultResult = CalibrationResult(
                      baselineY: 0,
                      jumpThreshold: 5.0,
                      duckThreshold: 2.0,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            ControllerScreen(calibration: defaultResult),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip (use defaults)',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/screens/controller_screen.dart';

@JS('requestMotionPermission')
external JSPromise<JSBoolean> _jsRequestMotionPermission();

@JS('isIOSNonSafari')
external JSBoolean _jsIsIOSNonSafari();

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
  String? _sensorError;
  bool _sensorStalled = false;
  bool _iosChromeDetected = false;

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
    _calibrator.onSensorStalled = () {
      if (mounted) setState(() => _sensorStalled = true);
    };

    // Flag iOS Chrome/Firefox/Edge so we can steer the user to Safari
    // where motion-sensor access actually works.
    if (kIsWeb) {
      try {
        _iosChromeDetected = _jsIsIOSNonSafari().toDart;
      } catch (_) {
        _iosChromeDetected = false;
      }
    }
  }

  @override
  void dispose() {
    _calibrator.cancel();
    super.dispose();
  }

  Future<void> _startCalibration() async {
    // Request motion permission on web (required for iOS Safari)
    if (kIsWeb) {
      final granted = await _requestWebMotionPermission();
      if (!granted) {
        setState(() => _sensorError =
            'Motion sensor permission denied.\nPlease allow motion access and try again.');
        return;
      }
    }
    setState(() {
      _sensorError = null;
      _sensorStalled = false;
    });
    _calibrator.startCalibration();
  }

  Future<bool> _requestWebMotionPermission() async {
    try {
      final result = await _jsRequestMotionPermission().toDart;
      return result.toDart;
    } catch (_) {
      // If the JS function isn't available or errors, assume permission granted
      return true;
    }
  }

  String get _instructionText => switch (_step) {
        CalibrationStep.idle =>
          'Hold your phone steady\nthen tap START',
        CalibrationStep.standStill => 'Hold still...',
        CalibrationStep.practiceJumps =>
          'Shake phone UP! (${(_progress * 2).ceil()}/2)',
        CalibrationStep.practiceDuck => 'Tilt phone DOWN!',
        CalibrationStep.done => "You're all set!",
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
                if (_iosChromeDetected)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent, width: 1),
                    ),
                    child: const Text(
                      'Best experience in Safari!\n'
                      'Chrome on iPhone blocks motion sensors.\n'
                      'Open this link in Safari, or use the on-screen buttons.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    ),
                  ),
                if (_sensorError != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _sensorError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),
                if (_sensorStalled && _result == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: const Text(
                      "Phone sensor isn't responding.\n"
                      "On iPhone: allow Motion & Orientation in Safari settings, "
                      "or tap 'Skip' below to use defaults.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                    ),
                  ),
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
                      jumpThreshold: 1.5,
                      duckThreshold: 0.8,
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

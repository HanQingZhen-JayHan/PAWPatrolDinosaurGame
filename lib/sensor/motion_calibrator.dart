import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:pup_dash/constants/game_constants.dart';

enum CalibrationStep { idle, standStill, practiceJumps, practiceDuck, done }

class CalibrationResult {
  final double baselineY;
  final double jumpThreshold;
  final double duckThreshold;

  const CalibrationResult({
    required this.baselineY,
    required this.jumpThreshold,
    required this.duckThreshold,
  });
}

class MotionCalibrator {
  StreamSubscription? _subscription;
  Timer? _standStillTimer;
  Timer? _sensorCheckTimer;
  CalibrationStep _step = CalibrationStep.idle;
  void Function(CalibrationStep step, double progress)? onProgress;
  void Function(CalibrationResult result)? onComplete;
  void Function()? onSensorStalled;

  CalibrationStep get step => _step;

  final List<double> _baselineSamples = [];
  final List<double> _jumpPeaks = [];
  final List<double> _duckSamples = [];
  int _eventCount = 0;

  Future<void> startCalibration() async {
    _step = CalibrationStep.standStill;
    _baselineSamples.clear();
    _jumpPeaks.clear();
    _duckSamples.clear();
    _eventCount = 0;

    final startTime = DateTime.now();
    double currentPeak = 0;

    // Wall-clock progress for standStill — advances even if sensor events
    // never arrive (e.g. iOS Safari permission not granted). Samples are
    // still collected opportunistically when events do fire.
    const tickMs = 50;
    _standStillTimer = Timer.periodic(Duration(milliseconds: tickMs), (t) {
      if (_step != CalibrationStep.standStill) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = min(
        1.0,
        elapsed / (GameConstants.calibrationStandStillSeconds * 1000),
      );
      onProgress?.call(_step, progress);
      if (progress >= 1.0) {
        t.cancel();
        _step = CalibrationStep.practiceJumps;
        currentPeak = 0;
        onProgress?.call(_step, 0);
      }
    });

    // If no sensor events arrive within 3 seconds, notify UI so the user
    // can be prompted to skip with defaults.
    _sensorCheckTimer = Timer(const Duration(seconds: 3), () {
      if (_eventCount == 0) onSensorStalled?.call();
    });

    // Use accelerometerEvents (includes gravity) for better web compatibility
    _subscription = accelerometerEventStream(
      samplingPeriod: Duration(
          milliseconds: GameConstants.sensorSampleIntervalMs),
    ).listen((event) {
      _eventCount++;

      switch (_step) {
        case CalibrationStep.standStill:
          _baselineSamples.add(event.y);
          // Progress is driven by the wall-clock timer above.
          break;

        case CalibrationStep.practiceJumps:
          final baseline = _averageBaseline;
          final deviation = (event.y - baseline).abs();
          currentPeak = max(currentPeak, deviation);

          // Detect a jump peak — lowered threshold for sensitivity
          if (currentPeak > 1.0 && deviation < 0.5) {
            _jumpPeaks.add(currentPeak);
            currentPeak = 0;
            final progress =
                _jumpPeaks.length / GameConstants.calibrationJumpCount;
            onProgress?.call(_step, min(1.0, progress));
            if (_jumpPeaks.length >= GameConstants.calibrationJumpCount) {
              _step = CalibrationStep.practiceDuck;
              onProgress?.call(_step, 0);
            }
          }
          break;

        case CalibrationStep.practiceDuck:
          _duckSamples.add(event.y);
          if (_duckSamples.length > 30) {
            _step = CalibrationStep.done;
            _subscription?.cancel();
            _finish();
          } else {
            onProgress?.call(
                _step, min(1.0, _duckSamples.length / 30));
          }
          break;

        default:
          break;
      }
    });
  }

  double get _averageBaseline {
    if (_baselineSamples.isEmpty) return 0;
    return _baselineSamples.reduce((a, b) => a + b) / _baselineSamples.length;
  }

  void _finish() {
    _standStillTimer?.cancel();
    _sensorCheckTimer?.cancel();
    final baseline = _averageBaseline;
    final avgJumpPeak = _jumpPeaks.isEmpty
        ? 3.0 // lower default for sensitivity
        : _jumpPeaks.reduce((a, b) => a + b) / _jumpPeaks.length;
    final jumpThreshold = avgJumpPeak * GameConstants.jumpThresholdFactor;

    // Duck threshold
    final avgDuck = _duckSamples.isEmpty
        ? 1.5
        : (_duckSamples.reduce((a, b) => a + b) / _duckSamples.length -
                baseline)
            .abs();
    final duckThreshold = max(0.8, avgDuck * 0.4);

    final result = CalibrationResult(
      baselineY: baseline,
      jumpThreshold: jumpThreshold,
      duckThreshold: duckThreshold,
    );

    _step = CalibrationStep.done;
    onProgress?.call(CalibrationStep.done, 1.0);
    onComplete?.call(result);
  }

  void cancel() {
    _subscription?.cancel();
    _standStillTimer?.cancel();
    _sensorCheckTimer?.cancel();
    _step = CalibrationStep.idle;
  }
}

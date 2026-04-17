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
  CalibrationStep _step = CalibrationStep.idle;
  void Function(CalibrationStep step, double progress)? onProgress;
  void Function(CalibrationResult result)? onComplete;

  CalibrationStep get step => _step;

  final List<double> _baselineSamples = [];
  final List<double> _jumpPeaks = [];
  final List<double> _duckSamples = [];

  Future<void> startCalibration() async {
    _step = CalibrationStep.standStill;
    _baselineSamples.clear();
    _jumpPeaks.clear();
    _duckSamples.clear();

    final startTime = DateTime.now();
    double currentPeak = 0;

    _subscription = userAccelerometerEventStream(
      samplingPeriod: Duration(
          milliseconds: GameConstants.sensorSampleIntervalMs),
    ).listen((event) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      switch (_step) {
        case CalibrationStep.standStill:
          _baselineSamples.add(event.y);
          final progress = min(
            1.0,
            elapsed / (GameConstants.calibrationStandStillSeconds * 1000),
          );
          onProgress?.call(_step, progress);
          if (progress >= 1.0) {
            _step = CalibrationStep.practiceJumps;
            currentPeak = 0;
            onProgress?.call(_step, 0);
          }
          break;

        case CalibrationStep.practiceJumps:
          final baseline = _averageBaseline;
          final deviation = (event.y - baseline).abs();
          currentPeak = max(currentPeak, deviation);

          // Detect a jump peak when acceleration returns near baseline after spike
          if (currentPeak > 2.0 && deviation < 1.0) {
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
          if (_duckSamples.length > 50) {
            // ~1 second of data
            _step = CalibrationStep.done;
            _subscription?.cancel();
            _finish();
          } else {
            onProgress?.call(
                _step, min(1.0, _duckSamples.length / 50));
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
    final baseline = _averageBaseline;
    final avgJumpPeak = _jumpPeaks.isEmpty
        ? 8.0
        : _jumpPeaks.reduce((a, b) => a + b) / _jumpPeaks.length;
    final jumpThreshold = avgJumpPeak * GameConstants.jumpThresholdFactor;

    // Duck threshold: difference from baseline during crouch
    final avgDuck = _duckSamples.isEmpty
        ? 3.0
        : (_duckSamples.reduce((a, b) => a + b) / _duckSamples.length -
                baseline)
            .abs();
    final duckThreshold = max(1.5, avgDuck * 0.5);

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
    _step = CalibrationStep.idle;
  }
}

import 'dart:async';
import 'dart:collection';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:pup_dash/constants/game_constants.dart';
import 'package:pup_dash/models/message.dart';
import 'package:pup_dash/sensor/motion_calibrator.dart';
import 'package:pup_dash/sensor/motion_state.dart';

class MotionDetector {
  final CalibrationResult calibration;
  final MotionStateManager _stateManager = MotionStateManager();
  StreamSubscription? _subscription;

  /// Called when a game input action is detected.
  void Function(String action)? onAction;

  /// Called each sample with debug info: (rawY, filteredY, deviation, threshold).
  void Function(double rawY, double filteredY, double deviation)? onDebugSample;

  final Queue<double> _filterBuffer = Queue<double>();
  DateTime _lastJumpTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _duckStartTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _inDuckCandidate = false;

  MotionDetector({required this.calibration});

  MotionState get state => _stateManager.state;

  void start() {
    _stateManager.reset();
    _filterBuffer.clear();

    // Use accelerometerEvents (includes gravity) for better web compatibility
    _subscription = accelerometerEventStream(
      samplingPeriod: Duration(
          milliseconds: GameConstants.sensorSampleIntervalMs),
    ).listen(_processSample);
  }

  void _processSample(AccelerometerEvent event) {
    // Low-pass filter: moving average
    _filterBuffer.addLast(event.y);
    if (_filterBuffer.length > GameConstants.filterWindowSize) {
      _filterBuffer.removeFirst();
    }
    final filteredY =
        _filterBuffer.reduce((a, b) => a + b) / _filterBuffer.length;

    final deviation = filteredY - calibration.baselineY;
    final now = DateTime.now();

    onDebugSample?.call(event.y, filteredY, deviation);

    // Jump detection: any significant acceleration spike
    if (deviation.abs() > calibration.jumpThreshold &&
        _stateManager.state == MotionState.standing) {
      final timeSinceLastJump =
          now.difference(_lastJumpTime).inMilliseconds;
      if (timeSinceLastJump > GameConstants.jumpDebounceDurationMs) {
        _lastJumpTime = now;
        if (_stateManager.transitionTo(MotionState.jumping)) {
          onAction?.call(InputAction.jump);
          // Auto-return to standing after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _stateManager.transitionTo(MotionState.standing);
          });
        }
      }
      return;
    }

    // Duck detection: sustained tilt/deviation
    if (deviation < -calibration.duckThreshold &&
        _stateManager.state == MotionState.standing) {
      if (!_inDuckCandidate) {
        _inDuckCandidate = true;
        _duckStartTime = now;
      } else {
        final sustained =
            now.difference(_duckStartTime).inMilliseconds;
        if (sustained >= GameConstants.duckSustainMs) {
          if (_stateManager.transitionTo(MotionState.ducking)) {
            onAction?.call(InputAction.duckStart);
          }
        }
      }
      return;
    }

    // Return from duck when back near baseline
    if (_stateManager.state == MotionState.ducking &&
        deviation.abs() < calibration.duckThreshold * 0.7) {
      if (_stateManager.transitionTo(MotionState.standing)) {
        onAction?.call(InputAction.duckEnd);
      }
    }

    // Reset duck candidate if deviation returned to normal
    if (deviation >= -calibration.duckThreshold) {
      _inDuckCandidate = false;
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _stateManager.reset();
  }

  void dispose() {
    stop();
  }
}

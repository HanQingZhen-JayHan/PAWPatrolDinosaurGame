import 'dart:async';
import 'dart:collection';

import 'package:sensors_plus/sensors_plus.dart';

import 'package:paw_patrol_runner/constants/game_constants.dart';
import 'package:paw_patrol_runner/models/message.dart';
import 'package:paw_patrol_runner/sensor/motion_calibrator.dart';
import 'package:paw_patrol_runner/sensor/motion_state.dart';

class MotionDetector {
  final CalibrationResult calibration;
  final MotionStateManager _stateManager = MotionStateManager();
  StreamSubscription? _subscription;

  /// Called when a game input action is detected.
  void Function(String action)? onAction;

  final Queue<double> _filterBuffer = Queue<double>();
  DateTime _lastJumpTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _duckStartTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _inDuckCandidate = false;

  MotionDetector({required this.calibration});

  MotionState get state => _stateManager.state;

  void start() {
    _stateManager.reset();
    _filterBuffer.clear();

    _subscription = userAccelerometerEventStream(
      samplingPeriod: Duration(
          milliseconds: GameConstants.sensorSampleIntervalMs),
    ).listen(_processSample);
  }

  void _processSample(UserAccelerometerEvent event) {
    // Low-pass filter: moving average
    _filterBuffer.addLast(event.y);
    if (_filterBuffer.length > GameConstants.filterWindowSize) {
      _filterBuffer.removeFirst();
    }
    final filteredY =
        _filterBuffer.reduce((a, b) => a + b) / _filterBuffer.length;

    final deviation = filteredY - calibration.baselineY;
    final now = DateTime.now();

    // Jump detection: spike above threshold
    if (deviation.abs() > calibration.jumpThreshold &&
        _stateManager.state == MotionState.standing) {
      final timeSinceLastJump =
          now.difference(_lastJumpTime).inMilliseconds;
      if (timeSinceLastJump > GameConstants.jumpDebounceDurationMs) {
        _lastJumpTime = now;
        if (_stateManager.transitionTo(MotionState.jumping)) {
          onAction?.call(InputAction.jump);
          // Auto-return to standing after a short delay (jump arc)
          Future.delayed(const Duration(milliseconds: 600), () {
            _stateManager.transitionTo(MotionState.standing);
          });
        }
      }
      return;
    }

    // Duck detection: sustained deviation below threshold
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
        deviation.abs() < calibration.duckThreshold * 0.5) {
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

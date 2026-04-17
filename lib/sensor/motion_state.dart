enum MotionState { standing, jumping, ducking }

class MotionStateManager {
  MotionState _state = MotionState.standing;
  void Function(MotionState from, MotionState to)? onTransition;

  MotionState get state => _state;

  bool transitionTo(MotionState newState) {
    // Valid transitions:
    // standing → jumping, standing → ducking
    // jumping → standing (landing)
    // ducking → standing (stand up)
    final valid = switch ((_state, newState)) {
      (MotionState.standing, MotionState.jumping) => true,
      (MotionState.standing, MotionState.ducking) => true,
      (MotionState.jumping, MotionState.standing) => true,
      (MotionState.ducking, MotionState.standing) => true,
      _ => false,
    };

    if (valid && _state != newState) {
      final from = _state;
      _state = newState;
      onTransition?.call(from, newState);
      return true;
    }
    return false;
  }

  void reset() {
    _state = MotionState.standing;
  }
}

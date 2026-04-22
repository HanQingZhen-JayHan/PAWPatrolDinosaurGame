import 'package:flutter/foundation.dart';

/// Develop mode toggle. When enabled:
/// - Room code is fixed (QR stays valid across host restarts)
/// - Game never ends automatically (no elimination, no auto-end)
/// - Difficulty is locked to easy level for testing logic
///
/// Toggle via [enabled]; listen to [notifier] for reactive updates.
class DevConfig {
  DevConfig._();

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(
    const bool.fromEnvironment('DEV_MODE', defaultValue: false),
  );

  static bool get enabled => notifier.value;
  static set enabled(bool value) => notifier.value = value;

  /// Fixed room code when dev mode is on. Uses the same 4-char uppercase
  /// format as generated codes so existing UI keeps working.
  static const String fixedRoomCode = 'DEV1';

  /// Easy-level tuning (only applied when [enabled]).
  static const double easyGameSpeed = 150.0;
  static const double easySpawnInterval = 4.0;

  /// Players don't die in dev mode, so lives are pinned at this value.
  static const int immortalLives = 99;
}

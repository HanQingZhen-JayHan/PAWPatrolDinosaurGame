import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Develop mode toggle. When enabled:
/// - Room code is fixed (QR stays valid across host restarts)
/// - Game never ends automatically (no elimination, no auto-end)
/// - Difficulty is locked to easy level for testing logic
///
/// The current value is persisted in [SharedPreferences] under [_prefsKey]
/// so it survives app restarts until the user changes it. Call [load]
/// once during app startup before UI reads [enabled].
class DevConfig {
  DevConfig._();

  static const String _prefsKey = 'pup_dash.dev_mode';

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(
    const bool.fromEnvironment('DEV_MODE', defaultValue: false),
  );

  static bool get enabled => notifier.value;

  /// Sets the flag and persists it. UI listeners on [notifier] react.
  static Future<void> setEnabled(bool value) async {
    notifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /// Load the persisted value at app startup. If nothing is stored,
  /// falls back to the build-time DEV_MODE define.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    if (stored != null) notifier.value = stored;
  }

  /// Fixed room code when dev mode is on. Uses the same 4-char uppercase
  /// format as generated codes so existing UI keeps working.
  static const String fixedRoomCode = 'DEV1';

  /// Easy-level tuning (only applied when [enabled]).
  static const double easyGameSpeed = 150.0;
  static const double easySpawnInterval = 4.0;

  /// Players don't die in dev mode, so lives are pinned at this value.
  static const int immortalLives = 99;
}

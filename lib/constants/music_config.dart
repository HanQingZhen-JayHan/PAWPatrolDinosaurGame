import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background-music toggle. Enabled by default. The current value is
/// persisted in [SharedPreferences] under [_prefsKey] so it survives
/// app restarts. Call [load] once during app startup before UI reads
/// [enabled].
class MusicConfig {
  MusicConfig._();

  static const String _prefsKey = 'pup_dash.music_enabled';

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(true);

  static bool get enabled => notifier.value;

  /// Sets the flag and persists it. UI listeners on [notifier] react.
  static Future<void> setEnabled(bool value) async {
    notifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /// Load the persisted value at app startup.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_prefsKey);
    if (stored != null) notifier.value = stored;
  }
}

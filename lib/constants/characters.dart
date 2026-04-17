import 'package:flutter/material.dart';

enum PupCharacter {
  chase('Chase', Colors.blue, '🐕'),
  marshall('Marshall', Colors.red, '🐾'),
  skye('Skye', Colors.pink, '🐩'),
  rubble('Rubble', Colors.yellow, '🦺'),
  rocky('Rocky', Colors.green, '♻️'),
  zuma('Zuma', Colors.orange, '🏄'),
  everest('Everest', Colors.purple, '❄️'),
  tracker('Tracker', Colors.brown, '🌴');

  const PupCharacter(this.displayName, this.color, this.emoji);

  final String displayName;
  final Color color;
  final String emoji;

  String get assetPrefix => name;
  String get iconAsset => 'assets/images/characters/${name}_icon.png';
  String get runAsset => 'assets/images/characters/${name}_run.png';
  String get jumpAsset => 'assets/images/characters/${name}_jump.png';
  String get duckAsset => 'assets/images/characters/${name}_duck.png';

  /// Characters that have a custom icon image asset.
  /// Add more here as assets are added.
  static const Set<String> _withIcon = {'skye', 'marshall'};
  bool get hasIconImage => _withIcon.contains(name);

  static PupCharacter? fromName(String name) {
    try {
      return PupCharacter.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}

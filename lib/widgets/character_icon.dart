import 'package:flutter/material.dart';

import 'package:pup_dash/constants/characters.dart';

/// Displays a character icon — uses image asset if available, emoji as fallback.
class CharacterIcon extends StatelessWidget {
  final PupCharacter? character;
  final double size;

  const CharacterIcon({super.key, required this.character, this.size = 32});

  @override
  Widget build(BuildContext context) {
    if (character == null) {
      return Text('🐕', style: TextStyle(fontSize: size));
    }
    if (character!.hasIconImage) {
      return Image.asset(
        character!.iconAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Text(character!.emoji, style: TextStyle(fontSize: size)),
      );
    }
    return Text(character!.emoji, style: TextStyle(fontSize: size));
  }
}

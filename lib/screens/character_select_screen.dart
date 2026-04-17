import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/characters.dart';
import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/screens/calibration_screen.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Pup!'),
        backgroundColor: PupTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PupTheme.backgroundLight, PupTheme.backgroundDark],
          ),
        ),
        child: Consumer<ControllerProvider>(
          builder: (context, controller, _) {
            final takenCharacters = controller.lobbyPlayers
                .where((p) =>
                    p['character'] != null &&
                    p['id'] != controller.playerId)
                .map((p) => p['character'] as String)
                .toSet();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: PupCharacter.values.length,
                itemBuilder: (context, index) {
                  final character = PupCharacter.values[index];
                  final isTaken = takenCharacters.contains(character.name);
                  final isSelected =
                      controller.selectedCharacter == character;

                  return GestureDetector(
                    onTap: isTaken
                        ? null
                        : () {
                            controller.selectCharacter(character);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isTaken
                            ? Colors.grey.withValues(alpha: 0.5)
                            : isSelected
                                ? character.color.withValues(alpha: 0.9)
                                : character.color.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: PupTheme.goldStar, width: 4)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: PupTheme.goldStar
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(character.emoji,
                              style: TextStyle(
                                  fontSize: isTaken ? 32 : 48)),
                          const SizedBox(height: 8),
                          Text(
                            character.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (isTaken)
                            const Text('TAKEN',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Consumer<ControllerProvider>(
        builder: (context, controller, _) {
          return Container(
            color: PupTheme.backgroundDark,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: controller.selectedCharacter != null
                  ? () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const CalibrationScreen()),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PupTheme.goldStar,
                foregroundColor: PupTheme.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('NEXT',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}

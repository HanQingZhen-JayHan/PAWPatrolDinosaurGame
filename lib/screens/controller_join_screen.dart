import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/providers/controller_provider.dart';
import 'package:pup_dash/providers/network_provider.dart';
import 'package:pup_dash/screens/character_select_screen.dart';

class ControllerJoinScreen extends StatefulWidget {
  const ControllerJoinScreen({super.key});

  @override
  State<ControllerJoinScreen> createState() => _ControllerJoinScreenState();
}

class _ControllerJoinScreenState extends State<ControllerJoinScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: 'Player');
  bool _connecting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _connecting = true);
    final controller = context.read<ControllerProvider>();

    try {
      await controller.connect(code);
      controller.join(_nameController.text.trim());

      if (mounted && controller.isConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join room: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Game'),
        backgroundColor: PupTheme.primaryRed,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 48, color: PupTheme.goldStar),
              const SizedBox(height: 16),
              const Text(
                'Enter the room code\nshown on the host screen',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              // Name input
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Room code input
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Room Code (e.g. ABCD)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                maxLength: 4,
                onSubmitted: (_) => _joinRoom(),
              ),
              const SizedBox(height: 16),
              _connecting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _joinRoom,
                      icon: const Icon(Icons.login),
                      label: const Text('JOIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PupTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                      ),
                    ),
              const SizedBox(height: 24),
              Consumer<NetworkProvider>(
                builder: (context, network, _) {
                  if (network.status == ConnectionStatus.error) {
                    return Text(
                      network.errorMessage,
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

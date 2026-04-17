import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:paw_patrol_runner/constants/theme.dart';
import 'package:paw_patrol_runner/providers/controller_provider.dart';
import 'package:paw_patrol_runner/providers/network_provider.dart';
import 'package:paw_patrol_runner/screens/character_select_screen.dart';

class ControllerJoinScreen extends StatefulWidget {
  const ControllerJoinScreen({super.key});

  @override
  State<ControllerJoinScreen> createState() => _ControllerJoinScreenState();
}

class _ControllerJoinScreenState extends State<ControllerJoinScreen> {
  final _ipController = TextEditingController();
  final _nameController = TextEditingController(text: 'Player');
  bool _connecting = false;

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _connectManual() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    final wsUrl = ip.startsWith('ws://') ? ip : 'ws://$ip/ws';
    await _connect(wsUrl);
  }

  Future<void> _connect(String wsUrl) async {
    setState(() => _connecting = true);
    final controller = context.read<ControllerProvider>();

    try {
      await controller.connect(wsUrl);
      controller.join(_nameController.text.trim());

      if (mounted && controller.isConnected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
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
        backgroundColor: PawTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PawTheme.backgroundLight, PawTheme.backgroundDark],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 24),
              // Manual IP input
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Host IP:Port (e.g. 192.168.1.100:8080)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.url,
                onSubmitted: (_) => _connectManual(),
              ),
              const SizedBox(height: 16),
              _connecting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _connectManual,
                      icon: const Icon(Icons.wifi),
                      label: const Text('CONNECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PawTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                      ),
                    ),
              const SizedBox(height: 32),
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

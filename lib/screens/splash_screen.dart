import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pup_dash/constants/theme.dart';
import 'package:pup_dash/screens/controller_join_screen.dart';
import 'package:pup_dash/screens/mode_select_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? initialRoomCode;
  const SplashScreen({super.key, this.initialRoomCode});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final destination = widget.initialRoomCode != null
            ? ControllerJoinScreen(initialRoomCode: widget.initialRoomCode!)
            : const ModeSelectScreen();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PupTheme.backgroundLight, PupTheme.backgroundDark],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 100, color: PupTheme.goldStar),
                const SizedBox(height: 24),
                Text(
                  'PUP DASH',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ENDLESS RUNNER',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: PupTheme.goldStar,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: PupTheme.goldStar,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

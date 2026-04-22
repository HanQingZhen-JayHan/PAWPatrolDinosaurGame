import 'package:flutter/material.dart';

import 'package:pup_dash/constants/dev_config.dart';

/// Thin red banner shown across the top of any screen when dev mode is on.
/// Wrap a screen body with [DevModeBanner] to inject it at the top.
class DevModeBanner extends StatelessWidget {
  final Widget child;

  const DevModeBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevConfig.notifier,
      builder: (context, enabled, _) {
        if (!enabled) return child;
        return Column(
          children: [
            Material(
              color: Colors.red.shade700,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bug_report, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'DEV MODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

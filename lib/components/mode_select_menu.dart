import 'package:flutter/material.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/state_parameter.dart';

class ModeSelectMenu extends StatelessWidget {
  final SuikaGame game;

  const ModeSelectMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(40.0),
          border: Border.all(
            color: const Color(0xFF4A4A8A),
            width: 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 36),

            // Normal Mode
            _ModeButton(
              label: 'Normal',
              icon: Icons.sports_esports,
              color: const Color(0xFF9162E8),
              description: 'Standard ball sizes',
              onTap: () {
                isEasyMode = false;
                game.startGame();
              },
            ),
            const SizedBox(height: 20),

            // Easy Mode
            _ModeButton(
              label: 'Easy',
              icon: Icons.sentiment_satisfied_alt,
              color: const Color(0xFFF9A825),
              description: 'Balls are half the size',
              onTap: () {
                isEasyMode = true;
                game.startGame();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

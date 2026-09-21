import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/suika_game.dart';

class EvolutionGuideButton extends StatelessWidget {
  final SuikaGame game;

  const EvolutionGuideButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: game.openEvolutionGuide,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.buttonBackground,
          foregroundColor: AppTheme.buttonText,
          padding: const EdgeInsets.all(12),
          shape: const CircleBorder(),
          elevation: 0,
        ),
        child: const Icon(Icons.auto_awesome, size: 20),
      ),
    );
  }
}

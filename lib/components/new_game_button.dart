import 'package:flutter/material.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/app_theme.dart';

class NewGameButton extends StatelessWidget {
  final SuikaGame game;

  const NewGameButton({super.key, required this.game});

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
      child: ElevatedButton.icon(
        onPressed: game.resetGame,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('New Game'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.buttonBackground,
          foregroundColor: AppTheme.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

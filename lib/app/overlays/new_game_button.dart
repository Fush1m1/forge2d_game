import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/suika_game.dart';

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
        onPressed: game.openModeSelect,
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

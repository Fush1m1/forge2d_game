import 'package:flutter/material.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/app_theme.dart';

class GameOverMenu extends StatelessWidget {
  final SuikaGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppTheme.overlayBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: AppTheme.overlayBorder,
            width: AppTheme.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                color: AppTheme.gameOverText,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    offset: Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: game.resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonBackground,
                foregroundColor: AppTheme.buttonText,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('New Game'),
            ),
          ],
        ),
      ),
    );
  }
}

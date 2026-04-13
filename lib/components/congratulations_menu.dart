import 'package:flutter/material.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/app_theme.dart';

class CongratulationsMenu extends StatelessWidget {
  final SuikaGame game;

  const CongratulationsMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppTheme.overlayBackground.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: AppTheme.overlayBorder,
            width: AppTheme.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: const Text(
                'Congratulations!',
                style: TextStyle(
                  color: AppTheme.congratulationsText,
                  fontSize: 48,
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
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: game.resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryButtonBackground,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
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

import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Confirmation shown when "New Game" is tapped mid-play. Tapping outside
/// the card dismisses it and lets the current game continue; tapping
/// "New Game" inside actually resets.
class ConfirmNewGameMenu extends StatelessWidget {
  final SuikaGame game;

  const ConfirmNewGameMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.cancelResetGame,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.overlayBackground.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(
                  color: AppTheme.overlayBorder,
                  width: AppTheme.borderWidth / 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Start New Game?',
                    style: TextStyle(
                      color: AppTheme.titleText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your current progress will be lost.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: game.cancelResetGame,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: game.resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.buttonBackground,
                          foregroundColor: AppTheme.buttonText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium,
                            ),
                          ),
                        ),
                        child: const Text('New Game'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

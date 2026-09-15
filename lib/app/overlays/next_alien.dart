import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/suika_game.dart';

class NextAlien extends StatelessWidget {
  final SuikaGame game;

  const NextAlien({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.overlayBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.overlayBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              color: AppTheme.shadowColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder(
            valueListenable: game.gameState,
            builder: (context, state, _) {
              return SizedBox(
                width: 20,
                height: 20,
                child: SpriteWidget(
                  sprite: game.aliens.getSprite(
                    game.ballDefinitionFor(state.nextBallLevel).spriteName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

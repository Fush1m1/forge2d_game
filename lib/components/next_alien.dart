import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/components/alien_ball.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/app_theme.dart';

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
          ValueListenableBuilder<int>(
            valueListenable: game.nextBallNotifier,
            builder: (context, nextNumber, _) {
              return SizedBox(
                width: 50,
                height: 50,
                child: SpriteWidget(
                  sprite: game.aliens.getSprite(getAlienSpriteName(nextNumber)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

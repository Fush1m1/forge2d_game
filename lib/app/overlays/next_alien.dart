import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class NextAlien extends StatelessWidget {
  final SuikaGame game;

  const NextAlien({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEXT',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

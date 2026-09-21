import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class GameOverMenu extends StatelessWidget {
  final SuikaGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        color: colorScheme.primary,
        elevation: 12,
        shadowColor: colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: game.resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text('NEW GAME'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

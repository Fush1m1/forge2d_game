import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class CongratulationsMenu extends StatelessWidget {
  final SuikaGame game;

  const CongratulationsMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.black,
        elevation: 12,
        shadowColor: colorScheme.tertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.tertiary, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(
                  'CONGRATULATIONS!',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: colorScheme.tertiary, blurRadius: 30),
                      const Shadow(color: Colors.black, blurRadius: 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: game.resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text('NEW GAME'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
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

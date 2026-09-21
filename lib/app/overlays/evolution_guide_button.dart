import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class EvolutionGuideButton extends StatelessWidget {
  final SuikaGame game;

  const EvolutionGuideButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: game.openEvolutionGuide,
      icon: const Icon(Icons.info, size: 20),
      style: IconButton.styleFrom(
        shape: CircleBorder(
          side: BorderSide(color: colorScheme.onPrimary, width: 2),
        ),
      ),
    );
  }
}

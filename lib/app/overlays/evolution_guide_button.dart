import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

const _deepViolet = Color(0xFF3D0080);

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
        backgroundColor: _deepViolet,
        foregroundColor: colorScheme.onPrimary,
        shape: CircleBorder(
          side: BorderSide(color: colorScheme.onPrimary, width: 2),
        ),
      ),
    );
  }
}

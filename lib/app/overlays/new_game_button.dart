import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class NewGameButton extends StatelessWidget {
  final SuikaGame game;

  const NewGameButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: game.openModeSelect,
      icon: const Icon(Icons.refresh, size: 20),
      label: const Text(
        'NEW GAME',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.onPrimary, width: 2),
        ),
      ),
    );
  }
}

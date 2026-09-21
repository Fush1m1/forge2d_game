import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class NewGameButton extends StatelessWidget {
  final SuikaGame game;

  const NewGameButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: game.openModeSelect,
      icon: const Icon(Icons.refresh, size: 20),
      label: const Text('NEW GAME'),
      style: FilledButton.styleFrom(elevation: 4, shadowColor: Colors.black),
    );
  }
}

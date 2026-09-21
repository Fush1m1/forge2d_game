import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

const _deepViolet = Color(0xFF3D0080);

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
        backgroundColor: _deepViolet,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.onPrimary, width: 2),
        ),
      ),
    );
  }
}

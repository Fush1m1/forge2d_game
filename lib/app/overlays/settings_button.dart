import 'package:flutter/material.dart';
import 'package:forge2d_game/game/suika_game.dart';

class SettingsButton extends StatelessWidget {
  final SuikaGame game;

  const SettingsButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: game.openSettings,
      icon: const Icon(Icons.settings, size: 20),
      style: IconButton.styleFrom(elevation: 4, shadowColor: Colors.black),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:forge2d_game/components/new_game_button.dart';
import 'package:forge2d_game/components/next_alien.dart';
import 'package:forge2d_game/game.dart';

class TopControls extends StatelessWidget {
  final SuikaGame game;

  const TopControls({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.topRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NewGameButton(game: game),
              const SizedBox(height: 16),
              NextAlien(game: game),
            ],
          ),
        ),
      ),
    );
  }
}

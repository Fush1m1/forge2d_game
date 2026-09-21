import 'package:flutter/material.dart';
import 'package:forge2d_game/app/overlays/evolution_guide_button.dart';
import 'package:forge2d_game/app/overlays/jev_drop_button.dart';
import 'package:forge2d_game/app/overlays/new_game_button.dart';
import 'package:forge2d_game/app/overlays/next_alien.dart';
import 'package:forge2d_game/app/overlays/settings_button.dart';
import 'package:forge2d_game/game/suika_game.dart';

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsButton(game: game),
                  const SizedBox(width: 12),
                  EvolutionGuideButton(game: game),
                  const SizedBox(width: 12),
                  NewGameButton(game: game),
                ],
              ),
              const SizedBox(height: 16),
              NextAlien(game: game),
              const SizedBox(height: 12),
              JevDropButton(game: game),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'package:forge2d_game/components/game_over_menu.dart';
import 'package:forge2d_game/components/congratulations_menu.dart';
import 'package:forge2d_game/components/mode_select_menu.dart';
import 'package:forge2d_game/components/top_controls.dart';

void main() {
  runApp(
    SafeArea(
      child: GameWidget<SuikaGame>.controlled(
        gameFactory: SuikaGame.new,
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverMenu(game: game),
          'Congratulations': (context, game) =>
              CongratulationsMenu(game: game),
          'ModeSelect': (context, game) => ModeSelectMenu(game: game),
          'TopControls': (context, game) => TopControls(game: game),
        },
      ),
    ),
  );
}

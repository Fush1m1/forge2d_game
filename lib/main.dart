import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';
import 'package:forge2d_game/utils/app_theme.dart';
import 'package:forge2d_game/components/game_over_menu.dart';

void main() {
  runApp(
    SafeArea(
      child: GameWidget<SuikaGame>.controlled(
        gameFactory: SuikaGame.new,
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverMenu(game: game),
        },
      ),
    ),
  );
}

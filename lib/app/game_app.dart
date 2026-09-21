import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/model/game_overlay.dart';
import '../game/suika_game.dart';
import 'overlays/congratulations_menu.dart';
import 'overlays/evolution_guide_menu.dart';
import 'overlays/game_over_menu.dart';
import 'overlays/mode_select_menu.dart';
import 'overlays/top_controls.dart';

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: SafeArea(
        child: GameWidget<SuikaGame>.controlled(
          gameFactory: SuikaGame.new,
          overlayBuilderMap: {
            GameOverlay.gameOver: (context, game) => GameOverMenu(game: game),
            GameOverlay.congratulations:
                (context, game) => CongratulationsMenu(game: game),
            GameOverlay.modeSelect:
                (context, game) => ModeSelectMenu(game: game),
            GameOverlay.topControls: (context, game) => TopControls(game: game),
            GameOverlay.evolutionGuide:
                (context, game) => EvolutionGuideMenu(game: game),
          },
        ),
      ),
    );
  }
}

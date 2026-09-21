import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/model/game_overlay.dart';
import '../game/services/app_settings.dart';
import '../game/suika_game.dart';
import 'overlays/congratulations_menu.dart';
import 'overlays/evolution_guide_menu.dart';
import 'overlays/game_over_menu.dart';
import 'overlays/mode_select_menu.dart';
import 'overlays/settings_menu.dart';
import 'overlays/top_controls.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  final AppSettings _appSettings = AppSettings();

  @override
  void dispose() {
    _appSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: _appSettings.state,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: settings.colorSeed,
              brightness: Brightness.dark,
              dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
            ),
          ),
          home: Scaffold(
            body: SafeArea(
              child: GameWidget<SuikaGame>.controlled(
                gameFactory: () => SuikaGame(appSettings: _appSettings),
                overlayBuilderMap: {
                  GameOverlay.gameOver:
                      (context, game) => GameOverMenu(game: game),
                  GameOverlay.congratulations:
                      (context, game) => CongratulationsMenu(game: game),
                  GameOverlay.modeSelect:
                      (context, game) => ModeSelectMenu(game: game),
                  GameOverlay.topControls:
                      (context, game) => TopControls(game: game),
                  GameOverlay.evolutionGuide:
                      (context, game) => EvolutionGuideMenu(game: game),
                  GameOverlay.settings:
                      (context, game) => SettingsMenu(game: game),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

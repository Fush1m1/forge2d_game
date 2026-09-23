import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart'
    hide PointerCancelEvent, PointerDownEvent, PointerMoveEvent, PointerUpEvent;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shake/shake.dart';

import '../shared/forge2d/body_removal.dart';
import 'components/alien_ball.dart';
import 'components/background.dart';
import 'components/brick.dart';
import 'components/debug_info.dart';
import 'components/easy_mode_message.dart';
import 'components/ground.dart';
import 'components/screen_flash.dart';
import 'config/game_constants.dart';
import 'game_audio.dart';
import 'gameplay_controller.dart';
import 'input/drop_controller.dart';
import 'input/tilt_controller.dart';
import 'jev_controller.dart';
import 'level_builder.dart';
import 'model/ball_definition.dart';
import 'model/game_mode.dart';
import 'model/game_overlay.dart';
import 'model/game_state.dart';
import 'model/stage.dart';
import 'services/app_settings.dart';
import 'services/game_session.dart';
import 'services/jev_assistant.dart';

class SuikaGame extends Forge2DGame
    with
        TapCallbacks,
        PointerMoveCallbacks,
        HasCollisionDetection,
        WidgetsBindingObserver {
  SuikaGame({GameSession? session, AppSettings? appSettings})
    : session = session ?? GameSession(),
      appSettings = appSettings ?? AppSettings(),
      super(zoom: worldScale, gravity: Vector2(0, worldGravity));

  final GameSession session;
  final AppSettings appSettings;
  final DropController _dropController = DropController();
  final TiltController _tiltController = TiltController();
  final Random _random = Random();
  double _appliedTiltGravityX = 0;

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  late final LevelBuilder _levelBuilder;
  late final GameAudio _audio;
  late final GameplayController _gameplay;
  late final JevController _jev;
  late final ShakeDetector _shakeDetector;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Vector2 _dropPosition = Vector2.zero();
  String _lastTapLog = 'Tap: -';

  ValueNotifier<GameState> get gameState => session.state;
  GameMode? get mode => session.mode;
  bool get isEasyMode => mode == GameMode.easy;
  JevAssistant get jevAssistant => _jev.assistant;

  BallDefinition ballDefinitionFor(int level) => BallDefinition.forLevel(level);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    WidgetsBinding.instance.addObserver(this);
    camera.viewport.add(DebugInfoComponent());
    camera.viewport.add(EasyModeMessageComponent(isEasyMode: () => isEasyMode));

    final backgroundImage = await images.load('colored_grass.png');
    final spriteSheets = await Future.wait([
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_aliens.png',
        xmlPath: 'spritesheet_aliens.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_elements.png',
        xmlPath: 'spritesheet_elements.xml',
      ),
      XmlSpriteSheet.load(
        imagePath: 'spritesheet_tiles.png',
        xmlPath: 'spritesheet_tiles.xml',
      ),
    ]);
    aliens = spriteSheets[0];
    elements = spriteSheets[1];
    tiles = spriteSheets[2];
    _levelBuilder = LevelBuilder(
      world: world,
      camera: camera,
      tiles: tiles,
      elements: elements,
      random: _random,
    );
    _audio = GameAudio(appSettings);
    await _audio.load();
    _gameplay = GameplayController(
      world: world,
      camera: camera,
      session: session,
      appSettings: appSettings,
      audio: _audio,
    );
    _jev = JevController(
      world: world,
      camera: camera,
      session: session,
      appSettings: appSettings,
      gameplay: _gameplay,
    );
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (event) => _shakeStackedBalls(),
    );
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      (event) => _tiltController.update(event.x),
      onError: (Object _) {},
      cancelOnError: true,
    );

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await _levelBuilder.build(Stage.classic);
    pauseEngine();
    overlays.add(GameOverlay.modeSelect);
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    session.dispose();
    _audio.dispose();
    _shakeDetector.stopListening();
    _accelerometerSubscription?.cancel();
    _jev.dispose();
    super.onRemove();
  }

  void _clearBoard() {
    _gameplay.reset();
    for (final ground in world.children.whereType<Ground>().toList()) {
      removeBodyComponent(world, ground);
    }
    for (final brick in world.children.whereType<Brick>().toList()) {
      removeBodyComponent(world, brick);
    }
    _tiltController.reset();
    _appliedTiltGravityX = 0;
    world.gravity = Vector2(0, appSettings.state.value.worldGravity);
  }

  void startGame(GameMode selectedMode, Stage selectedStage) {
    _clearBoard();
    session.start(selectedMode, selectedStage);
    unawaited(_levelBuilder.build(selectedStage));
    overlays.remove(GameOverlay.modeSelect);
    overlays.add(GameOverlay.topControls);
    resumeEngine();
  }

  void resetGame() {
    _clearBoard();
    session.reset();
    overlays.remove(GameOverlay.gameOver);
    overlays.remove(GameOverlay.congratulations);
    overlays.remove(GameOverlay.topControls);
    overlays.remove(GameOverlay.evolutionGuide);
    overlays.remove(GameOverlay.settings);
    pauseEngine();
    overlays.add(GameOverlay.modeSelect);
  }

  void openEvolutionGuide() => overlays.add(GameOverlay.evolutionGuide);

  void closeEvolutionGuide() => overlays.remove(GameOverlay.evolutionGuide);

  /// Shows the mode-select dialog on top of the current game, without
  /// touching it. Used by the mid-play "New Game" button: picking a mode
  /// commits to a fresh game via [startGame]; dismissing it via
  /// [closeModeSelect] leaves the current game untouched.
  void openModeSelect() => overlays.add(GameOverlay.modeSelect);

  void closeModeSelect() => overlays.remove(GameOverlay.modeSelect);

  void openSettings() => overlays.add(GameOverlay.settings);

  void closeSettings() => overlays.remove(GameOverlay.settings);

  /// Debug-only: shows the Game Over overlay without actually losing, so the
  /// screen can be checked without playing a full round out.
  void debugShowGameOver() {
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.gameOver);
  }

  /// Debug-only: shows the Congratulations overlay without actually winning.
  void debugShowCongratulations() {
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.congratulations);
  }

  /// Debug-only: see [JevController.resetAuthentication].
  void debugResetJevAuthentication() => _jev.resetAuthentication();

  void requestMerge(AlienBall first, AlienBall second) {
    if (_gameplay.requestMerge(first, second)) {
      _showCongratulations();
    }
  }

  void onBallCollision(Object other) => _gameplay.onBallCollision(other);

  void _shakeStackedBalls() {
    if (!session.isPlaying) return;
    // ポップコーンみたいに、たまに通常より強いシェイクが来る。
    final settings = appSettings.state.value;
    final isStrongShake =
        _random.nextDouble() < settings.strongShakeProbability;
    final multiplier = isStrongShake ? strongShakeMultiplier : 1.0;
    // shakeStrength(水平成分)を基準に、上下・回転成分もデフォルト比を
    // 保ったまま一緒にスケールさせる。
    final shakeScale = settings.shakeStrength / shakeMaxHorizontalVelocity;
    for (final ball in world.children.whereType<AlienBall>()) {
      final body = ball.bodyComponent.body;
      final horizontal =
          (_random.nextDouble() * 2 - 1) * settings.shakeStrength * multiplier;
      final upward =
          -_random.nextDouble() *
          shakeMaxUpwardVelocity *
          shakeScale *
          multiplier;
      body.linearVelocity = body.linearVelocity + Vector2(horizontal, upward);
      body.angularVelocity +=
          (_random.nextDouble() * 2 - 1) *
          shakeMaxAngularVelocity *
          shakeScale *
          multiplier;
    }
    if (isStrongShake) {
      camera.viewport.add(ScreenFlashComponent());
    }
  }

  void _showCongratulations() {
    _audio.playCongratulations();
    session.congratulate();
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.congratulations);
  }

  bool _dropBall({bool allowWhileBusy = false}) =>
      _gameplay.dropBall(_dropPosition.x, allowWhileBusy: allowWhileBusy);

  /// Asks Jev to pick which lane to drop the next ball into (issue #48),
  /// then drops it there. See [JevController.chooseDropPosition].
  Future<void> requestJevDrop() async {
    final position = await _jev.chooseDropPosition();
    if (position == null) return;
    _dropPosition = position;
    _dropBall();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _lastTapLog =
        'Tap: (${event.canvasPosition.x.toStringAsFixed(1)}, '
        '${event.canvasPosition.y.toStringAsFixed(1)})';
    DebugInfo.add(_lastTapLog);
    if (event.handled || !session.isPlaying) return;
    _dropPosition = _canvasToWorld(event.canvasPosition);
    _dropController.beginPress();
    if (_dropBall()) {
      _dropController.recordInitialDrop();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _dropController.endPress();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_dropController.update(dt, mode)) {
      _dropBall(allowWhileBusy: true);
    }
    _gameplay.applyPendingChanges();
    _gameplay.removeOffscreenBalls();
    _updateTiltGravity();
    _updateDebugInfo();
    _updateGameOver();
  }

  void _updateTiltGravity() {
    final targetGravityX =
        session.isPlaying ? _tiltController.horizontalGravity : 0.0;
    // Setting world.gravity wakes up every body, so only do it when the
    // tilt actually changed enough to matter, otherwise settled balls would
    // never be able to fall back asleep.
    if ((targetGravityX - _appliedTiltGravityX).abs() < tiltGravityEpsilon) {
      return;
    }
    _appliedTiltGravityX = targetGravityX;
    world.gravity = Vector2(
      targetGravityX,
      appSettings.state.value.worldGravity,
    );
  }

  Vector2 _canvasToWorld(Vector2 canvasPosition) {
    final visibleRect = camera.visibleWorldRect;
    return Vector2(
      canvasPosition.x / worldScale + visibleRect.left,
      canvasPosition.y / worldScale + visibleRect.top,
    );
  }

  void _updateDebugInfo() {
    if (!isMounted) return;

    final threshold =
        (camera.visibleWorldRect.bottom - groundTileSize) *
        (isEasyMode ? gameOverHeightMultiplierEasy : 1);
    DebugInfo.add('Obj Height: ${_gameplay.objectHeight.toStringAsFixed(1)}');
    DebugInfo.add('Threshold: ${threshold.toStringAsFixed(1)}');
    DebugInfo.add('Ball count: ${_gameplay.ballCount}');
    DebugInfo.add(_lastTapLog);
    // Split on commas so a long JSON response wraps onto multiple lines
    // instead of running off the edge of the screen.
    for (final line in _jev.lastResponseLog.split(',')) {
      DebugInfo.add(line);
    }
  }

  void _updateGameOver() {
    if (!session.isPlaying) return;
    final threshold =
        (camera.visibleWorldRect.bottom - groundTileSize) *
        (isEasyMode ? gameOverHeightMultiplierEasy : 1);
    if (_gameplay.objectHeight <= threshold) return;

    _audio.playGameOver();
    session.gameOver();
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.gameOver);
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:flutter/material.dart'
    hide PointerCancelEvent, PointerDownEvent, PointerMoveEvent, PointerUpEvent;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shake/shake.dart';

import 'components/alien_ball.dart';
import 'components/background.dart';
import 'components/brick.dart';
import 'components/debug_info.dart';
import 'components/easy_mode_message.dart';
import 'components/ground.dart';
import 'components/screen_flash.dart';
import 'components/merge_burst.dart';
import 'config/game_constants.dart';
import 'input/drop_controller.dart';
import 'input/tilt_controller.dart';
import 'model/ball_definition.dart';
import 'model/brick_file_names.dart';
import 'model/game_mode.dart';
import 'model/game_overlay.dart';
import 'model/game_state.dart';
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
  final JevAssistant jevAssistant = JevAssistant();
  final DropController _dropController = DropController();
  final TiltController _tiltController = TiltController();
  final List<AlienBall> _ballsToRemove = [];
  final List<AlienBall> _ballsToAdd = [];
  final Random _random = Random();
  int _ballCount = 0;
  double _appliedTiltGravityX = 0;

  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  late final AudioPool _soundPool;
  late final ShakeDetector _shakeDetector;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  Vector2 _dropPosition = Vector2.zero();
  double _objectHeight = 0;
  String _lastTapLog = 'Tap: -';

  ValueNotifier<GameState> get gameState => session.state;
  GameMode? get mode => session.mode;
  bool get isEasyMode => mode == GameMode.easy;

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
    await FlameAudio.audioCache.loadAll([
      gameOverSoundFile,
      congratulationsSoundFile,
    ]);
    _soundPool = await FlameAudio.createPool(
      mergeSoundFile,
      minPlayers: 2,
      maxPlayers: 4,
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
    await _buildInitialLevel();
    pauseEngine();
    overlays.add(GameOverlay.modeSelect);
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    session.dispose();
    _soundPool.dispose();
    _shakeDetector.stopListening();
    _accelerometerSubscription?.cancel();
    jevAssistant.dispose();
    super.onRemove();
  }

  Future<void> _buildInitialLevel() async {
    final visibleRect = camera.visibleWorldRect;
    await world.addAll([
      for (
        var x = visibleRect.left;
        x < visibleRect.right + groundTileSize;
        x += groundTileSize
      )
        Ground(
          Vector2(x, (visibleRect.height - groundTileSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
    for (var row = 0; row < initialBrickRowCount; row++) {
      final height = firstBrickHeight + brickHeightInterval * row;
      await _addBrick(visibleRect.left / 3 * 2, height);
      await _addBrick(visibleRect.right / 3 * 2, height);
    }
  }

  Future<void> _addBrick(double x, double height) async {
    final y = camera.visibleWorldRect.bottom - (height + groundTileSize);
    final type = BrickType.metal;
    final size = BrickSize.size70x140;
    await world.add(
      Brick(
        type: type,
        size: size,
        damage: BrickDamage.none,
        position: Vector2(x, y),
        sprites: brickFileNames(
          type,
          size,
        ).map((key, filename) => MapEntry(key, elements.getSprite(filename))),
      ),
    );
  }

  void _clearBoard() {
    for (final ball in world.children.whereType<AlienBall>().toList()) {
      ball.removeFromParent();
    }
    _ballsToRemove.clear();
    _ballsToAdd.clear();
    _ballCount = 0;
    _objectHeight = 0;
    _tiltController.reset();
    _appliedTiltGravityX = 0;
    world.gravity = Vector2(0, appSettings.state.value.worldGravity);
  }

  void startGame(GameMode selectedMode) {
    _clearBoard();
    session.start(selectedMode);
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

  /// Debug-only: clears the remembered Jev password authentication, so the
  /// "Ask Jev" password prompt can be re-tested without clearing all app
  /// data.
  void debugResetJevAuthentication() {
    appSettings.resetJevAuthentication();
  }

  void requestMerge(AlienBall first, AlienBall second) {
    if (first.number != second.number ||
        first.hasCombined ||
        second.hasCombined) {
      return;
    }
    first.hasCombined = true;
    second.hasCombined = true;
    if (first.number >= 10) return;

    _soundPool.start(volume: appSettings.state.value.soundVolume);
    final newLevel = first.number + 1;
    final newPosition =
        (first.bodyComponent.body.position +
            second.bodyComponent.body.position) /
        2;
    final newBallSize = ballDefinitionFor(newLevel).diameterFor(mode!);
    _ballsToRemove.addAll([first, second]);
    _ballsToAdd.add(
      AlienBall(
        posi: newPosition,
        number: newLevel,
        ballSize: newBallSize,
        speed: 0,
        hasFirstCollisionExecuted: true,
      ),
    );
    world.add(
      MergeBurstComponent(
        position: newPosition,
        ballSize: newBallSize,
        level: newLevel,
        scaleBoost: appSettings.state.value.mergeEffectScale,
      ),
    );
    // 2つ消えて1つ増えるので、combine 1回につき差し引き1個減る。
    _ballCount--;
    if (newLevel == 10) {
      _showCongratulations();
    }
  }

  void onBallCollision(Object other) {
    session.markDropReady();
    if (other is! Brick) _objectHeight = _calculateObjectHeight();
  }

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
    FlameAudio.play(
      congratulationsSoundFile,
      volume: appSettings.state.value.soundVolume,
    );
    session.congratulate();
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.congratulations);
  }

  double _calculateObjectHeight() {
    var height = 0.0;
    for (final ball in world.children.whereType<AlienBall>()) {
      height = max(height, _heightOf(ball));
    }
    return height;
  }

  bool _dropBall({bool allowWhileBusy = false}) {
    if (!session.isPlaying || (!session.isDropReady && !allowWhileBusy)) {
      return false;
    }
    final visibleRect = camera.visibleWorldRect;
    if (_dropPosition.x <= visibleRect.left ||
        _dropPosition.x >= visibleRect.right) {
      return false;
    }

    final level = session.takeNextBall(allowWhileBusy: allowWhileBusy);
    final ballSize = ballDefinitionFor(level).diameterFor(mode!);
    final xPosition = _dropPosition.x.clamp(
      visibleRect.left + ballSize / 2,
      visibleRect.right - ballSize / 2,
    );
    world.add(
      AlienBall(
        posi: Vector2(xPosition, dropY),
        number: level,
        ballSize: ballSize,
        speed: initialDropSpeed,
        hasFirstCollisionExecuted: false,
      ),
    );
    _ballCount++;
    return true;
  }

  /// Asks Jev to pick which lane to drop the next ball into (issue #48),
  /// then drops it there. This is an on-demand, single HTTP call kicked off
  /// by a player tapping the "Ask Jev" button — not something run every
  /// frame, since Jev's API latency only makes sense for a one-shot
  /// decision, not continuous autoplay.
  Future<void> requestJevDrop() async {
    if (!session.isPlaying || !session.isDropReady) {
      jevAssistant.state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage: 'ゲームがプレイ中でないため、Jevに依頼できません。',
      );
      return;
    }

    final visibleRect = camera.visibleWorldRect;
    final laneWidth = visibleRect.width / jevLaneCount;
    final nextLevel = session.state.value.nextBallLevel;
    final laneCriteria = <String, String>{};
    final laneCenterX = <String, double>{};

    for (var i = 0; i < jevLaneCount; i++) {
      final laneKey = jevLaneKeys[i];
      final left = visibleRect.left + laneWidth * i;
      final right = left + laneWidth;
      laneCenterX[laneKey] = (left + right) / 2;

      AlienBall? topBall;
      for (final ball in world.children.whereType<AlienBall>()) {
        final x = ball.bodyComponent.body.position.x;
        if (x < left || x >= right) continue;
        if (topBall == null ||
            ball.bodyComponent.body.position.y <
                topBall.bodyComponent.body.position.y) {
          topBall = ball;
        }
      }
      laneCriteria[laneKey] =
          topBall == null
              ? 'Empty lane, no balls stacked yet.'
              : 'Topmost ball here is level ${topBall.number} out of 10, '
                  'stack height '
                  '${_heightOf(topBall).toStringAsFixed(1)} world units.';
    }

    final boardState =
        'This is a Suika-style merge puzzle. Balls are numbered 1 to 10; '
        'when two balls of the same number touch they merge into one ball '
        'of the next number up. The board is divided into $jevLaneCount '
        'lanes from left to right (${jevLaneKeys.join(', ')}). The next '
        'ball about to be dropped is level $nextLevel. Choose the lane '
        'that is most likely to merge this ball with an existing one of '
        'the same level, or failing that, the lane that keeps the overall '
        'stack lowest.';

    final chosenLane = await jevAssistant.chooseLane(
      apiKey: jevDefaultApiKey,
      boardState: boardState,
      laneCriteria: laneCriteria,
    );
    final centerX = chosenLane == null ? null : laneCenterX[chosenLane];
    if (centerX == null) return;

    _dropPosition = Vector2(centerX, 0);
    _dropBall();
  }

  double _heightOf(AlienBall ball) =>
      (camera.visibleWorldRect.bottom - groundTileSize) -
      ball.bodyComponent.body.position.y;

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
    _applyPendingBallChanges();
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

  void _applyPendingBallChanges() {
    for (final ball in _ballsToRemove) {
      ball.removeFromParent();
    }
    _ballsToRemove.clear();
    for (final ball in _ballsToAdd) {
      world.add(ball);
    }
    _ballsToAdd.clear();
  }

  void _updateDebugInfo() {
    if (!isMounted) return;

    final threshold =
        (camera.visibleWorldRect.bottom - groundTileSize) *
        (isEasyMode ? gameOverHeightMultiplierEasy : 1);
    DebugInfo.add('Obj Height: ${_objectHeight.toStringAsFixed(1)}');
    DebugInfo.add('Threshold: ${threshold.toStringAsFixed(1)}');
    DebugInfo.add('Ball count: $_ballCount');
    DebugInfo.add(_lastTapLog);
  }

  void _updateGameOver() {
    if (!session.isPlaying) return;
    final threshold =
        (camera.visibleWorldRect.bottom - groundTileSize) *
        (isEasyMode ? gameOverHeightMultiplierEasy : 1);
    if (_objectHeight <= threshold) return;

    FlameAudio.play(
      gameOverSoundFile,
      volume: appSettings.state.value.soundVolume,
    );
    session.gameOver();
    overlays.remove(GameOverlay.topControls);
    overlays.add(GameOverlay.gameOver);
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart'
    hide PointerMoveEvent, PointerDownEvent, PointerUpEvent, PointerCancelEvent;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:forge2d_game/components/alien_ball.dart';
import 'package:forge2d_game/components/background.dart';
import 'package:forge2d_game/components/brick.dart';
import 'package:forge2d_game/components/ground.dart';
import 'package:forge2d_game/components/debug_info.dart';
import 'package:forge2d_game/components/easy_mode_message.dart';
import 'package:forge2d_game/utils/config.dart';
import 'package:forge2d_game/utils/state_parameter.dart';

class SuikaGame extends Forge2DGame
    with
        TapCallbacks,
        PointerMoveCallbacks,
        HasCollisionDetection,
        WidgetsBindingObserver {
  SuikaGame() : super(zoom: scale, gravity: Vector2(0, dbGravity));

  final Random rng = Random();
  double touchX = 0.0;
  double touchY = 0.0;
  Vector2 _bottomRight = Vector2.zero();
  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  double _objHeight = 0;
  bool _isGameOver = false;

  final List<AlienBall> ballToRemove = [];
  final List<AlienBall> ballToAdd = [];

  // バースト（連射）用
  bool _isHolding = false;
  int _burstCount = 0;
  double _burstTimer = 0.0;
  double _pressDuration = 0.0;
  static const double _burstInterval = 0.15; // 0.15秒ごとに発射
  static const double _longPressThreshold = 0.5; // 0.5秒以上で長押し判定

  // 次に出るボールを通知するためのNotifier
  final ValueNotifier<int> nextBallNotifier = ValueNotifier(1);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final screenWidth = size.x;
    final screenHeight = size.y;

    ///座標の倍率計算
    widthPer = screenWidth / widthBase;
    heightPer = screenHeight / heightBase;
    allPer = (widthPer + heightPer) / 2;

    /// ブラウザのリサイズに追随してワールド座標の右下を更新
    _bottomRight = camera.visibleWorldRect.bottomRight.toVector2();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    WidgetsBinding.instance.addObserver(this);
    camera.viewport.add(DebugInfoComponent());
    camera.viewport.add(EasyModeMessageComponent());
    numberOfFirstBall = rng.nextInt(randomNum) + starRandomNum;
    numberOfSecondBall = rng.nextInt(randomNum) + starRandomNum;

    final visibleRect = camera.visibleWorldRect;
    _bottomRight = visibleRect.bottomRight.toVector2();
    nextBallNotifier.value = numberOfSecondBall;

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

    await world.add(Background(sprite: Sprite(backgroundImage)));
    await addGround();
    await addBrick(camera.visibleWorldRect.left / 2, 1.8);
    await addBrick(camera.visibleWorldRect.right / 2, 1.8);
    await addBrick(camera.visibleWorldRect.left / 2, 3.0);
    await addBrick(camera.visibleWorldRect.right / 2, 3.0);
    await addBrick(camera.visibleWorldRect.left / 2, 4.2);
    await addBrick(camera.visibleWorldRect.right / 2, 4.2);

    /// ゲーム開始前にモード選択を表示
    pauseEngine();
    overlays.add('ModeSelect');
  }

  Future<void> addGround() {
    return world.addAll([
      for (
        var x = camera.visibleWorldRect.left;
        x < camera.visibleWorldRect.right + groundSize;
        x += groundSize
      )
        Ground(
          Vector2(x, (camera.visibleWorldRect.height - groundSize) / 2),
          tiles.getSprite('grass.png'),
        ),
    ]);
  }

  Future<void> addBrick(double x, double h) async {
    final y = camera.visibleWorldRect.bottom - groundSize * h;
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

  double calcObjHeight() {
    final balls = world.children.whereType<AlienBall>();
    if (balls.isEmpty) {
      return 0.0;
    }

    for (final ball in balls) {
      final yi =
          (camera.visibleWorldRect.bottom - groundSize) -
          ball.bodyComponent.body.position.y;
      if (yi > _objHeight) {
        _objHeight = yi;
      }
    }
    return _objHeight;
  }

  void startGame() {
    overlays.remove('ModeSelect');
    overlays.add('TopControls');
    resumeEngine();
  }

  void resetGame() {
    world.children.whereType<AlienBall>().forEach((ball) {
      ball.removeFromParent();
    });
    ballToRemove.clear();
    ballToAdd.clear();
    _objHeight = 0;
    _isGameOver = false;
    tapOK = true;
    numberOfFirstBall = rng.nextInt(randomNum) + starRandomNum;
    numberOfSecondBall = rng.nextInt(randomNum) + starRandomNum;
    nextBallNotifier.value = numberOfSecondBall;
    overlays.remove('GameOver');
    overlays.remove('Congratulations');
    overlays.remove('TopControls');
    pauseEngine();
    overlays.add('ModeSelect');
  }

  void showCongratulations() {
    overlays.remove('TopControls');
    overlays.add('Congratulations');
  }

  void _updatePosition(Vector2 canvasPosition) {
    // 画面座標をワールド座標に変換（手動計算）
    touchX = canvasPosition.x / scale - _bottomRight.x;
    touchY = canvasPosition.y / scale - _bottomRight.y;
  }

  void _dropBall() {
    if (_isGameOver) return;
    if (tapOK || (isEasyMode && _isHolding)) {
      double ballSize = calcTypeSize(numberOfFirstBall, allPer);
      final visibleRect = camera.visibleWorldRect;
      final wallOffset = ballSize / 2;
      final dropLeft = visibleRect.left + wallOffset;
      final dropRight = visibleRect.right - wallOffset;

      if (touchX > visibleRect.left && touchX < visibleRect.right) {
        double xPosi = touchX.clamp(dropLeft, dropRight);
        final ball = AlienBall(
          posi: Vector2(xPosi, yDrop * heightPer),
          number: numberOfFirstBall,
          ballSize: ballSize,
          speed: firstSpeed,
          hasFirstCollisionExecuted: false,
        );
        world.add(ball);
        tapOK = false;

        ///次のballを決定する
        numberOfFirstBall = numberOfSecondBall;
        numberOfSecondBall = rng.nextInt(randomNum) + starRandomNum;
        nextBallNotifier.value = numberOfFirstBall;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver) return;
    super.onTapDown(event);
    if (!event.handled) {
      _updatePosition(event.canvasPosition);
      _isHolding = true;
      _burstCount = 0;
      _burstTimer = 0.0;
      _pressDuration = 0.0; // リセット

      // 最初の1発目
      if (tapOK) {
        _dropBall();
        _burstCount = 1;
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _isHolding = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _isHolding = false;
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _updatePosition(event.canvasPosition);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 連射ロジック
    if (isEasyMode && _isHolding && !_isGameOver) {
      _pressDuration += dt;
      // 長押し判定時間（0.5秒）を超えたら連射開始
      if (_pressDuration >= _longPressThreshold && _burstCount < 10) {
        _burstTimer += dt;
        if (_burstTimer >= _burstInterval) {
          _dropBall();
          _burstCount++;
          _burstTimer = 0.0;
        }
      }
    }

    // 保留されたエンティティの削除
    if (ballToRemove.isNotEmpty) {
      for (var ball in ballToRemove) {
        ball.removeFromParent();
      }
      ballToRemove.clear();
    }
    // 保留されたエンティティの追加
    if (ballToAdd.isNotEmpty) {
      ballToAdd.forEach(world.add);
      ballToAdd.clear();
    }

    double threshold =
        (camera.visibleWorldRect.bottom - groundSize) *
        (isEasyMode ? 2.0 : 1.0);

    if (isMounted) {
      DebugInfo.add('Obj Height: $_objHeight');
      DebugInfo.add('Threshold: $threshold');
      DebugInfo.add(
        'Ball count: ${world.children.whereType<AlienBall>().length}',
      );
    }

    if (isMounted && _objHeight > threshold && !_isGameOver) {
      _isGameOver = true;
      overlays.remove('TopControls');
      overlays.add('GameOver');
    }
  }

  /// 衝突検知時に呼ばれるメソッド
  void onballCollision(Object? other) {
    if (other is Brick) {
      tapOK = false;
      // TODO: 地面かボールに衝突するまでtapを受け付けない
      tapOK = true;
    } else {
      calcObjHeight();
      tapOK = true;
    }
  }
}

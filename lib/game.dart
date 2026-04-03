import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:forge2d_game/components/alien_ball.dart';
import 'package:forge2d_game/components/background.dart';
import 'package:forge2d_game/components/brick.dart';
import 'package:forge2d_game/components/ground.dart';
import 'package:forge2d_game/utils/debug_info.dart';
import 'package:forge2d_game/utils/config.dart';

class SuikaGame extends Forge2DGame
    with TapCallbacks, HasCollisionDetection, WidgetsBindingObserver {
  SuikaGame() : super(zoom: scale, gravity: Vector2(0, dbGravity));

  final Random rng = Random();
  int numberOfFirstBall = 1;
  int numberOfSecondBall = 1;
  double touchX = 0.0;
  double touchY = 0.0;
  Vector2 topLeft = Vector2.zero();
  Vector2 topRight = Vector2.zero();
  Vector2 bottomRight = Vector2.zero();
  Vector2 bottomLeft = Vector2.zero();
  late final XmlSpriteSheet aliens;
  late final XmlSpriteSheet elements;
  late final XmlSpriteSheet tiles;
  bool tapOK = true;
  double objHeight = 0;
  bool isGameOver = false;

  final List<AlienBall> ballToRemove = [];
  final List<AlienBall> ballToAdd = [];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final screenWidth = size.x;
    final screenHeight = size.y;

    ///座標の倍率計算
    widthPer = screenWidth / widthBase;
    heightPer = screenHeight / heightBase;
    allPer = (widthPer + heightPer) / 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    WidgetsBinding.instance.addObserver(this);
    camera.viewport.add(DebugInfoComponent());
    numberOfFirstBall = rng.nextInt(randomNum) + starRandomNum;
    numberOfSecondBall = rng.nextInt(randomNum) + starRandomNum;
    final visibleRect = camera.visibleWorldRect;
    topLeft = visibleRect.topLeft.toVector2();
    topRight = visibleRect.topRight.toVector2();
    bottomRight = visibleRect.bottomRight.toVector2();
    bottomLeft = visibleRect.bottomLeft.toVector2();

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
      if (yi > objHeight) {
        objHeight = yi;
      }
    }
    return objHeight;
  }


  void resetGame() {
    world.children.whereType<AlienBall>().forEach((ball) {
      ball.removeFromParent();
    });
    ballToRemove.clear();
    ballToAdd.clear();
    objHeight = 0;
    isGameOver = false;
    tapOK = true;
    numberOfFirstBall = rng.nextInt(randomNum) + starRandomNum;
    numberOfSecondBall = rng.nextInt(randomNum) + starRandomNum;
    overlays.remove('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    super.onTapDown(event);
    double xPosi;
    if (!event.handled && tapOK) {
      final touchPoint = event.canvasPosition;
      touchX = touchPoint.x / scale - bottomRight.x;
      touchY = touchPoint.y / scale - bottomRight.y;
      double ballSize = calcTypeSize(numberOfFirstBall, allPer);
      if (touchX > xStart && touchX < xEnd) {
        if (touchX >
                ((xStart * widthPer + ballSize / 2 + 10 / scale * widthPer)) &&
            touchX < (xEnd * widthPer - ballSize / 2)) {
          xPosi = touchX;
        } else if (touchX <=
            (xStart * widthPer + ballSize / 2 + 10 / scale * widthPer)) {
          xPosi = (xStart * widthPer + ballSize / 2 + 10 / scale * widthPer);
        } else if (touchX >= (xEnd * widthPer - ballSize / 2)) {
          xPosi = (xEnd * widthPer - ballSize / 2);
        } else {
          xPosi = touchX;
        }
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
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
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

    double threshold = camera.visibleWorldRect.bottom - groundSize;

    if (isMounted) {
      DebugInfo.add('Obj Height: $objHeight');
      DebugInfo.add(
        'Threshold: $threshold',
      );
      DebugInfo.add(
        'Ball count: ${world.children.whereType<AlienBall>().length}',
      );
    }

    if (isMounted &&
        objHeight > threshold && !isGameOver) {
      isGameOver = true;
      overlays.add('GameOver');
    }
  }

  /// 衝突検知時に呼ばれるメソッド
  void onballCollision() {
    final balls = children.whereType<AlienBall>();
    final allStopped = balls.every((ball) => !ball.bodyComponent.body.isAwake);
    if (allStopped) {
      calcObjHeight();
    }
    tapOK = true;
  }
}

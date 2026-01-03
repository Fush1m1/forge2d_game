import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';
import 'package:forge2d_game/components/ball.dart';
import 'package:forge2d_game/components/background.dart';
import 'package:forge2d_game/components/brick.dart';
import 'package:forge2d_game/components/ground.dart';
import 'package:forge2d_game/components/debug_info.dart';
import 'package:forge2d_game/config.dart';

final List<Ball> ballToRemove = [];
final List<Ball> ballToAdd = [];
List<Ball> allballs = [];

class SuikaGame extends Forge2DGame
    with TapCallbacks, HasCollisionDetection, WidgetsBindingObserver {
  SuikaGame() : super(zoom: scale, gravity: Vector2(0, dbGravity));
  final Random rng = Random();
  int firstType = 1;
  int secondType = 1;
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
    await images.loadAll(['01.png', '02.png', '03.png']);
    firstType = rng.nextInt(randomNum) + starRandomNum; // 1～4のランダムな整数
    secondType = rng.nextInt(randomNum) + starRandomNum; // 1～4のランダムな整数
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
    await addBrick(camera.visibleWorldRect.left);
    await addBrick(camera.visibleWorldRect.right);
    debugMode = true;
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

  Future<void> addBrick(double x) async {
    final y = camera.visibleWorldRect.bottom - groundSize * 1.8;
    final type = BrickType.metal;
    final size = BrickSize.size140x220;

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
    if (allballs.isEmpty) {
      return 0.0;
    }

    for (final ball in allballs) {
      final yi =
          (camera.visibleWorldRect.bottom - groundSize) -
          ball.bodyComponent.body.position.y;
      if (yi > objHeight) {
        objHeight = yi;
      }
    }
    print('objHeight: $objHeight');
    return objHeight;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    double hitSize = 0.0;
    double typeSize = 0.0;
    double xPosi = 0.0;
    if (!event.handled && tapOK) {
      final touchPoint = event.canvasPosition;
      touchX = touchPoint.x / scale - bottomRight.x;
      touchY = touchPoint.y / scale - bottomRight.y;
      typeSize = calcTypeSize(firstType, allPer);
      hitSize = typeSize;
      if (touchX > xStart && touchX < xEnd) {
        if (touchX >
                ((xStart * widthPer + hitSize / 2 + 10 / scale * widthPer)) &&
            touchX < (xEnd * widthPer - hitSize / 2)) {
          xPosi = touchX;
        } else if (touchX <=
            (xStart * widthPer + hitSize / 2 + 10 / scale * widthPer)) {
          xPosi = (xStart * widthPer + hitSize / 2 + 10 / scale * widthPer);
        } else if (touchX >= (xEnd * widthPer - hitSize / 2)) {
          xPosi = (xEnd * widthPer - hitSize / 2);
        } else {
          xPosi = touchX;
        }
        final ball = Ball(
          posi: Vector2(xPosi, yDrop * heightPer),
          type: firstType,
          typeSize: typeSize,
          hitSize: hitSize,
          speed: firstSpeed,
          firstTouch: false,
        );
        world.add(ball);
        tapOK = false;
        allballs.add(ball);

        ///次のballを決定する
        firstType = secondType;
        secondType = rng.nextInt(randomNum) + starRandomNum;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 保留されたエンティティの削除
    if (ballToRemove.isNotEmpty) {
      for (var ball in ballToRemove) {
        allballs.remove(ball);
        ball.removeFromParent();
      }
      ballToRemove.clear();
    }
    // 保留されたエンティティの追加
    if (ballToAdd.isNotEmpty) {
      ballToAdd.forEach(world.add);
      ballToAdd.clear();
    }

    if (isMounted) {
      DebugInfo.add('Obj Height: $objHeight');
      DebugInfo.add(
        'Threshold: ${(camera.visibleWorldRect.bottom - groundSize) / 3}',
      );
      DebugInfo.add('Ball count: ${allballs.length}');
    }

    if (isMounted &&
        objHeight > (camera.visibleWorldRect.bottom - groundSize) / 3) {
      world.addAll(
        [
          (position: Vector2(0.5, 0.5), color: Colors.white),
          (position: Vector2.zero(), color: Colors.orangeAccent),
        ].map(
          (e) => TextComponent(
            text: 'Game Over',
            anchor: Anchor.center,
            position: e.position,
            textRenderer: TextPaint(
              style: TextStyle(color: e.color, fontSize: 5),
            ),
          ),
        ),
      );
    }
  }

  // 衝突検知時に呼ばれるメソッド
  void onballCollision() {
    // tapOKの状態を変更する
    tapOK = true;
    final balls = children.whereType<Ball>();
    final allStopped = balls.every((ball) => !ball.bodyComponent.body.isAwake);
    if (allStopped) {
      calcObjHeight();
    }
  }
}

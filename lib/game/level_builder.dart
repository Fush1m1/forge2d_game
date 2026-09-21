import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_kenney_xml/flame_kenney_xml.dart';

import 'components/brick.dart';
import 'components/ground.dart';
import 'config/game_constants.dart';
import 'model/brick_file_names.dart';
import 'model/stage.dart';

/// Builds the floor and obstacle bricks for a [Stage] (issue #20).
///
/// Used once at launch with [Stage.classic] (so there's something behind
/// the mandatory first mode-select dialog), then again from
/// `SuikaGame.startGame` with whichever stage the player picked.
class LevelBuilder {
  LevelBuilder({
    required this.world,
    required this.camera,
    required this.tiles,
    required this.elements,
    Random? random,
  }) : _random = random ?? Random();

  final Forge2DWorld world;
  final CameraComponent camera;
  final XmlSpriteSheet tiles;
  final XmlSpriteSheet elements;
  final Random _random;

  Future<void> build(Stage stage) async {
    final visibleRect = camera.visibleWorldRect;
    final bumpAmplitude = stage.floorBumpAmplitude;
    await world.addAll([
      for (
        var x = visibleRect.left;
        x < visibleRect.right + groundTileSize;
        x += groundTileSize
      )
        Ground(
          Vector2(
            x,
            (visibleRect.height - groundTileSize) / 2 +
                (bumpAmplitude == 0
                    ? 0
                    : (_random.nextDouble() * 2 - 1) * bumpAmplitude),
          ),
          tiles.getSprite('grass.png'),
        ),
    ]);

    if (stage == Stage.classic) {
      // Reproduces the original fixed layout exactly: 3 rows, symmetric
      // metal columns, no randomness.
      for (var row = 0; row < initialBrickRowCount; row++) {
        final height = firstBrickHeight + brickHeightInterval * row;
        await _addBrick(
          visibleRect.left / 3 * 2,
          height,
          BrickType.metal,
          BrickSize.size70x140,
        );
        await _addBrick(
          visibleRect.right / 3 * 2,
          height,
          BrickType.metal,
          BrickSize.size70x140,
        );
      }
      return;
    }

    final (minCount, maxCount) = stage.obstacleCountRange;
    final obstacleCount =
        minCount == maxCount
            ? minCount
            : minCount + _random.nextInt(maxCount - minCount + 1);
    // Keep obstacles away from the very edges of the playfield.
    final inset = visibleRect.width * 0.15;
    for (var i = 0; i < obstacleCount; i++) {
      final type =
          stage.randomizeBrickVariety ? BrickType.randomType : BrickType.metal;
      final size =
          stage.randomizeBrickVariety
              ? BrickSize.randomSize
              : BrickSize.size70x140;
      final x =
          visibleRect.left +
          inset +
          _random.nextDouble() * (visibleRect.width - 2 * inset);
      final height =
          firstBrickHeight + brickHeightInterval * (i % initialBrickRowCount);
      await _addBrick(x, height, type, size);
    }
  }

  Future<void> _addBrick(
    double x,
    double height,
    BrickType type,
    BrickSize size,
  ) async {
    final y = camera.visibleWorldRect.bottom - (height + groundTileSize);
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/config/game_constants.dart';
import 'package:forge2d_game/game/model/stage.dart';

void main() {
  test('classic is a fixed count with no variety or floor bumps', () {
    expect(Stage.classic.obstacleCountRange, (2, 2));
    expect(Stage.classic.randomizeBrickVariety, isFalse);
    expect(Stage.classic.floorBumpAmplitude, 0);
  });

  test('scattered randomizes obstacle count and variety, flat floor', () {
    final (min, max) = Stage.scattered.obstacleCountRange;
    expect(min, lessThan(max));
    expect(Stage.scattered.randomizeBrickVariety, isTrue);
    expect(Stage.scattered.floorBumpAmplitude, 0);
  });

  test('rugged adds a floor bump capped below groundTileSize', () {
    expect(Stage.rugged.randomizeBrickVariety, isTrue);
    expect(Stage.rugged.floorBumpAmplitude, greaterThan(0));
    expect(Stage.rugged.floorBumpAmplitude, lessThan(groundTileSize));
  });

  test('every stage has a distinct label', () {
    final labels = Stage.values.map((s) => s.label).toSet();
    expect(labels.length, Stage.values.length);
  });
}

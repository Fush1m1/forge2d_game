import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/model/ball_definition.dart';
import 'package:forge2d_game/game/model/game_mode.dart';

void main() {
  test('ball definitions map each level to its asset and diameter', () {
    final ball = BallDefinition.forLevel(6);

    expect(ball.spriteName, 'alienBeige_suit.png');
    expect(ball.diameterFor(GameMode.normal), 80);
    expect(ball.diameterFor(GameMode.easy), 40);
  });

  test('unsupported ball level is rejected', () {
    expect(() => BallDefinition.forLevel(11), throwsArgumentError);
  });
}

import 'game_mode.dart';
import '../config/game_constants.dart';

class BallDefinition {
  const BallDefinition({
    required this.level,
    required this.diameter,
    required this.spriteName,
  });

  final int level;
  final double diameter;
  final String spriteName;

  /// Returns the diameter in Forge2D world units, not source-image pixels.
  double diameterFor(GameMode mode) {
    final modeMultiplier = mode == GameMode.easy ? 0.5 : 1.0;
    return diameter / worldScale * modeMultiplier;
  }

  static BallDefinition forLevel(int level) {
    final definition = _definitions[level];
    if (definition == null) {
      throw ArgumentError.value(level, 'level', 'must be between 1 and 10');
    }
    return definition;
  }

  static const Map<int, BallDefinition> _definitions = {
    1: BallDefinition(
      level: 1,
      diameter: 25,
      spriteName: 'alienBeige_round.png',
    ),
    2: BallDefinition(
      level: 2,
      diameter: 30,
      spriteName: 'alienBlue_round.png',
    ),
    3: BallDefinition(
      level: 3,
      diameter: 35,
      spriteName: 'alienGreen_round.png',
    ),
    4: BallDefinition(
      level: 4,
      diameter: 45,
      spriteName: 'alienPink_round.png',
    ),
    5: BallDefinition(
      level: 5,
      diameter: 60,
      spriteName: 'alienYellow_round.png',
    ),
    6: BallDefinition(
      level: 6,
      diameter: 80,
      spriteName: 'alienBeige_suit.png',
    ),
    7: BallDefinition(
      level: 7,
      diameter: 100,
      spriteName: 'alienBlue_suit.png',
    ),
    8: BallDefinition(
      level: 8,
      diameter: 120,
      spriteName: 'alienGreen_suit.png',
    ),
    9: BallDefinition(
      level: 9,
      diameter: 150,
      spriteName: 'alienPink_suit.png',
    ),
    10: BallDefinition(
      level: 10,
      diameter: 200,
      spriteName: 'alienYellow_suit.png',
    ),
  };
}

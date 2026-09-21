import '../config/game_constants.dart' as constants;

/// Selectable obstacle-layout presets (issue #20). Each game start rolls a
/// fresh layout for the chosen stage, so replaying the same stage doesn't
/// look identical every time (except [classic], which reproduces the
/// original fixed layout exactly).
enum Stage {
  classic,
  scattered,
  rugged;

  String get label => switch (this) {
    Stage.classic => 'CLASSIC',
    Stage.scattered => 'SCATTERED',
    Stage.rugged => 'RUGGED',
  };

  String get description => switch (this) {
    Stage.classic => 'The original fixed layout',
    Stage.scattered => 'Random obstacle count, position & type',
    Stage.rugged => 'Scattered, plus an uneven floor',
  };

  /// Inclusive (min, max) number of obstacle bricks to place. Classic is a
  /// fixed count, matching its fixed layout.
  (int min, int max) get obstacleCountRange => switch (this) {
    Stage.classic => (2, 2),
    Stage.scattered || Stage.rugged => (3, 6),
  };

  /// Whether obstacles should get a random [BrickType]/[BrickSize] each,
  /// instead of the classic fixed metal/70x140.
  bool get randomizeBrickVariety => this != Stage.classic;

  /// Max random per-tile vertical offset for the floor, in world units.
  /// Capped well below groundTileSize so adjacent tiles' collision boxes
  /// still overlap near their shared edge — a real gap would let balls
  /// fall through the floor.
  double get floorBumpAmplitude => switch (this) {
    Stage.rugged => constants.groundTileSize * 0.35,
    Stage.classic || Stage.scattered => 0,
  };
}

import 'dart:ui';

const double worldScale = 10;
const double worldGravity = 20;
const double initialDropSpeed = 40;
const double dropLineY = -100 / worldScale;
const double dropY = dropLineY - (50 / worldScale);
const double groundTileSize = 7;
const double brickScale = 0.5;
const double initialBrickSourceHeight = 140;
const double initialBrickWorldHeight =
    initialBrickSourceHeight / worldScale * brickScale;
const double firstBrickHeight = initialBrickWorldHeight / 2;
const double brickHeightInterval = initialBrickWorldHeight;
const int initialBrickRowCount = 3;
const double gameOverHeightMultiplierEasy = 2;
const double collisionSettleDuration = 0.5;
const String mergeSoundFile = 'merge.wav';
const String gameOverSoundFile = 'game_over.wav';
const String congratulationsSoundFile = 'congratulations.wav';
const double shakeMaxHorizontalVelocity = 12;
const double shakeMaxUpwardVelocity = 14;
const double shakeMaxAngularVelocity = 6;
const double tiltGravityEpsilon = 0.05;
const double strongShakeProbability = 0.2;
const double strongShakeMultiplier = 2.5;
const double screenFlashDuration = 0.35;

// 合体演出 (MergeBurstComponent): レベルが高い合体ほど大きく長く光らせる。
const int mergeBurstMinLevel = 2;
const int mergeBurstMaxLevel = 10;
const double mergeBurstBaseDuration = 0.3;
const double mergeBurstDurationBoost = 0.25;
const double mergeBurstBaseScale = 2.0;
const double mergeBurstScaleBoost = 3.0;
const Color mergeBurstColorLow = Color(0xFFFFF6C8);
const Color mergeBurstColorHigh = Color(0xFFFF7A1A);

// Jev連携 (issue #48): 盤面を横方向にこの数のレーンへ分割し、Jevに
// どのレーンへ落とすかを選んでもらう。
const int jevLaneCount = 5;
const List<String> jevLaneKeys = [
  'far_left',
  'left',
  'center',
  'right',
  'far_right',
];

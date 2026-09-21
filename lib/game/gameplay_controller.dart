import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../shared/forge2d/body_removal.dart';
import 'components/alien_ball.dart';
import 'components/brick.dart';
import 'components/merge_burst.dart';
import 'config/game_constants.dart';
import 'game_audio.dart';
import 'model/ball_definition.dart';
import 'services/app_settings.dart';
import 'services/game_session.dart';

/// Owns ball bookkeeping and the drop/merge/height-tracking gameplay loop:
/// dropping balls, merging matching pairs, tracking how tall the stack is,
/// and cleaning up balls that drift off-screen.
///
/// Deliberately does NOT touch overlays: only the actual `Game` object can
/// show/hide those, so [SuikaGame] reacts to [requestMerge]'s return value
/// (reached the max level) and to [objectHeight] crossing the game-over
/// threshold itself.
class GameplayController {
  GameplayController({
    required this.world,
    required this.camera,
    required this.session,
    required this.appSettings,
    required this.audio,
  });

  final Forge2DWorld world;
  final CameraComponent camera;
  final GameSession session;
  final AppSettings appSettings;
  final GameAudio audio;

  final List<AlienBall> _ballsToRemove = [];
  final List<AlienBall> _ballsToAdd = [];

  int _ballCount = 0;
  double _objectHeight = 0;

  int get ballCount => _ballCount;
  double get objectHeight => _objectHeight;

  /// Clears all balls and resets counters — e.g. before a new game starts.
  /// Does not touch Ground/Brick/gravity/tilt; that's SuikaGame's job.
  void reset() {
    for (final ball in world.children.whereType<AlienBall>().toList()) {
      _removeBall(ball);
    }
    _ballsToRemove.clear();
    _ballsToAdd.clear();
    _ballCount = 0;
    _objectHeight = 0;
  }

  bool dropBall(double xPosition, {bool allowWhileBusy = false}) {
    if (!session.isPlaying || (!session.isDropReady && !allowWhileBusy)) {
      return false;
    }
    final visibleRect = camera.visibleWorldRect;
    if (xPosition <= visibleRect.left || xPosition >= visibleRect.right) {
      return false;
    }

    final level = session.takeNextBall(allowWhileBusy: allowWhileBusy);
    final ballSize = BallDefinition.forLevel(level).diameterFor(session.mode!);
    final clampedX = xPosition.clamp(
      visibleRect.left + ballSize / 2,
      visibleRect.right - ballSize / 2,
    );
    world.add(
      AlienBall(
        posi: Vector2(clampedX, dropY),
        number: level,
        ballSize: ballSize,
        speed: initialDropSpeed,
        hasFirstCollisionExecuted: false,
      ),
    );
    _ballCount++;
    return true;
  }

  /// Attempts to merge [first] and [second]. Returns true if this merge
  /// reached the max level (10), so the caller can show the
  /// congratulations overlay.
  bool requestMerge(AlienBall first, AlienBall second) {
    if (first.number != second.number ||
        first.hasCombined ||
        second.hasCombined) {
      return false;
    }
    first.hasCombined = true;
    second.hasCombined = true;
    if (first.number >= 10) return false;

    audio.playMerge();
    final newLevel = first.number + 1;
    final newPosition =
        (first.bodyComponent.body.position +
            second.bodyComponent.body.position) /
        2;
    final newBallSize = BallDefinition.forLevel(
      newLevel,
    ).diameterFor(session.mode!);
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
    return newLevel == 10;
  }

  void onBallCollision(Object other) {
    session.markDropReady();
    if (other is! Brick) _objectHeight = calculateObjectHeight();
  }

  double calculateObjectHeight() {
    var height = 0.0;
    for (final ball in world.children.whereType<AlienBall>()) {
      height = max(height, heightOf(ball));
    }
    return height;
  }

  double heightOf(AlienBall ball) =>
      (camera.visibleWorldRect.bottom - groundTileSize) -
      ball.bodyComponent.body.position.y;

  void applyPendingChanges() {
    for (final ball in _ballsToRemove) {
      _removeBall(ball);
    }
    _ballsToRemove.clear();
    for (final ball in _ballsToAdd) {
      world.add(ball);
    }
    _ballsToAdd.clear();
  }

  /// Removes any ball that has drifted outside the playfield — e.g. tilt
  /// gravity pushing it past the left/right edge, since there are no side
  /// walls, or one somehow falling through the floor — so it doesn't sit
  /// forever as an uncountable, unmergeable ball inflating [ballCount].
  /// Deliberately does NOT check the top edge: every dropped ball starts
  /// above [camera]'s visible rect at `dropY` and falls in from there, so
  /// that would remove balls the instant they're dropped.
  void removeOffscreenBalls() {
    final visibleRect = camera.visibleWorldRect;
    for (final ball in world.children.whereType<AlienBall>().toList()) {
      final position = ball.bodyComponent.body.position;
      final margin = ball.ballSize / 2;
      final isOffscreen =
          position.x < visibleRect.left - margin ||
          position.x > visibleRect.right + margin ||
          position.y > visibleRect.bottom + margin;
      if (isOffscreen) {
        _removeBall(ball);
        _ballCount--;
      }
    }
  }

  /// Removes [ball], first destroying its [AlienBall.bodyComponent]'s
  /// Forge2D body if it never mounted — see [destroyBodyIfUnmounted].
  void _removeBall(AlienBall ball) {
    destroyBodyIfUnmounted(world, ball.bodyComponent);
    ball.removeFromParent();
  }
}

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'components/alien_ball.dart';
import 'config/game_constants.dart';
import 'gameplay_controller.dart';
import 'services/app_settings.dart';
import 'services/game_session.dart';
import 'services/jev_assistant.dart';

/// Owns the "Ask Jev" feature (issue #48): asking Jev
/// (https://jevtypesafeai.com/) which lane to drop the next ball into, and
/// tracking the request state ([assistant]) plus a truncated log of the
/// last response for the debug overlay.
class JevController {
  JevController({
    required this.world,
    required this.camera,
    required this.session,
    required this.appSettings,
    required this.gameplay,
    JevAssistant? assistant,
  }) : assistant = assistant ?? JevAssistant();

  final Forge2DWorld world;
  final CameraComponent camera;
  final GameSession session;
  final AppSettings appSettings;
  final GameplayController gameplay;
  final JevAssistant assistant;

  String _lastResponseLog = 'Jev res: -';

  /// Truncated summary of the last Jev response/error, shown in the debug
  /// logging overlay (including release builds) so a real reply can be
  /// checked without a device log/proxy.
  String get lastResponseLog => _lastResponseLog;

  void dispose() => assistant.dispose();

  /// Debug-only: clears the remembered Jev password authentication, so the
  /// "Ask Jev" password prompt can be re-tested without clearing all app
  /// data.
  void resetAuthentication() => appSettings.resetJevAuthentication();

  /// Asks Jev to pick which lane to drop the next ball into, and returns
  /// the world-space drop position for that lane, or `null` if dropping
  /// isn't currently possible or no lane was chosen. This is an on-demand,
  /// single HTTP call kicked off by a player tapping the "Ask Jev" button —
  /// not something run every frame, since Jev's API latency only makes
  /// sense for a one-shot decision, not continuous autoplay.
  Future<Vector2?> chooseDropPosition() async {
    if (!session.isPlaying || !session.isDropReady) {
      assistant.state.value = const JevAssistantState(
        status: JevRequestStatus.error,
        errorMessage: 'ゲームがプレイ中でないため、Jevに依頼できません。',
      );
      return null;
    }

    final visibleRect = camera.visibleWorldRect;
    final laneWidth = visibleRect.width / jevLaneCount;
    final nextLevel = session.state.value.nextBallLevel;
    final laneCriteria = <String, String>{};
    final laneCenterX = <String, double>{};

    for (var i = 0; i < jevLaneCount; i++) {
      final laneKey = jevLaneKeys[i];
      final left = visibleRect.left + laneWidth * i;
      final right = left + laneWidth;
      laneCenterX[laneKey] = (left + right) / 2;

      AlienBall? topBall;
      for (final ball in world.children.whereType<AlienBall>()) {
        final x = ball.bodyComponent.body.position.x;
        if (x < left || x >= right) continue;
        if (topBall == null ||
            ball.bodyComponent.body.position.y <
                topBall.bodyComponent.body.position.y) {
          topBall = ball;
        }
      }
      laneCriteria[laneKey] =
          topBall == null
              ? 'Empty lane, no balls stacked yet.'
              : 'Topmost ball here is level ${topBall.number} out of 10, '
                  'stack height '
                  '${gameplay.heightOf(topBall).toStringAsFixed(1)} world units.';
    }

    final boardState =
        'This is a Suika-style merge puzzle. Balls are numbered 1 to 10; '
        'when two balls of the same number touch they merge into one ball '
        'of the next number up. The board is divided into $jevLaneCount '
        'lanes from left to right, numbered ${jevLaneKeys.first} (leftmost) '
        'to ${jevLaneKeys.last} (rightmost). The next ball about to be '
        'dropped is level $nextLevel. Choose the lane that is most likely '
        'to merge this ball with an existing one of the same level, or '
        'failing that, the lane that keeps the overall stack lowest.';

    final chosenLane = await assistant.chooseLane(
      apiKey: jevDefaultApiKey,
      boardState: boardState,
      laneCriteria: laneCriteria,
    );
    _lastResponseLog = 'Jev res: ${_summarizeResponse()}';

    final centerX = chosenLane == null ? null : laneCenterX[chosenLane];
    return centerX == null ? null : Vector2(centerX, 0);
  }

  String _summarizeResponse() {
    final result = assistant.state.value;
    final body = result.rawResponseBody;
    if (body == null) return result.errorMessage ?? '(no response)';
    return body.length > 160 ? '${body.substring(0, 160)}...' : body;
  }
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/model/game_mode.dart';
import 'package:forge2d_game/game/model/game_phase.dart';
import 'package:forge2d_game/game/model/stage.dart';
import 'package:forge2d_game/game/services/game_session.dart';

void main() {
  test('session publishes mode selection state on reset', () {
    final session = GameSession(random: Random(1));
    addTearDown(session.dispose);

    expect(session.state.value.phase, GamePhase.modeSelect);
    expect(session.state.value.mode, isNull);
    expect(session.state.value.stage, isNull);
    expect(session.state.value.nextBallLevel, inInclusiveRange(1, 2));
    expect(session.isDropReady, isTrue);
  });

  test('session advances its queue while a game is playing', () {
    final session = GameSession(random: Random(1));
    addTearDown(session.dispose);
    session.start(GameMode.easy, Stage.scattered);

    final droppedBall = session.takeNextBall();

    expect(droppedBall, inInclusiveRange(1, 2));
    expect(session.state.value.phase, GamePhase.playing);
    expect(session.state.value.mode, GameMode.easy);
    expect(session.state.value.stage, Stage.scattered);
    expect(session.state.value.nextBallLevel, inInclusiveRange(1, 2));
    expect(session.isDropReady, isFalse);
    session.markDropReady();
    expect(session.isDropReady, isTrue);
  });

  test('terminal transitions retain the selected mode and stage', () {
    final session = GameSession(random: Random(1));
    addTearDown(session.dispose);
    session.start(GameMode.normal, Stage.rugged);
    session.gameOver();

    expect(session.state.value.phase, GamePhase.gameOver);
    expect(session.state.value.mode, GameMode.normal);
    expect(session.state.value.stage, Stage.rugged);
  });

  test('maxLevelReached tracks drops and merges, resetting per round', () {
    final session = GameSession(random: Random(1));
    addTearDown(session.dispose);
    expect(session.maxLevelReached, 0);

    session.start(GameMode.normal, Stage.rugged);
    final dropped = session.takeNextBall();
    expect(session.maxLevelReached, dropped);

    session.recordLevel(7);
    session.recordLevel(4);
    expect(session.maxLevelReached, 7);

    session.start(GameMode.easy, Stage.rugged);
    expect(session.maxLevelReached, 0);
  });
}

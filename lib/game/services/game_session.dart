import 'dart:math';

import 'package:flutter/foundation.dart';

import '../model/game_mode.dart';
import '../model/game_phase.dart';
import '../model/game_state.dart';
import '../model/stage.dart';

class GameSession {
  GameSession({Random? random}) : _random = random ?? Random() {
    reset();
  }

  final Random _random;
  final ValueNotifier<GameState> state = ValueNotifier(
    const GameState.modeSelect(),
  );
  int _currentBallLevel = 1;
  int _followingBallLevel = 1;
  bool _isDropReady = true;

  GameMode? get mode => state.value.mode;
  Stage? get stage => state.value.stage;
  bool get isPlaying => state.value.phase == GamePhase.playing;
  bool get isDropReady => _isDropReady;

  void start(GameMode mode, Stage stage) {
    _publish(phase: GamePhase.playing, mode: mode, stage: stage);
  }

  int takeNextBall({bool allowWhileBusy = false}) {
    if (!isPlaying || (!_isDropReady && !allowWhileBusy)) {
      throw StateError('A ball can only be dropped while playing.');
    }
    final ballLevel = _currentBallLevel;
    _currentBallLevel = _followingBallLevel;
    _followingBallLevel = _randomBallLevel();
    _isDropReady = false;
    _publish(phase: GamePhase.playing, mode: mode, stage: stage);
    return ballLevel;
  }

  void gameOver() =>
      _publish(phase: GamePhase.gameOver, mode: mode, stage: stage);

  void markDropReady() => _isDropReady = true;

  void congratulate() =>
      _publish(phase: GamePhase.congratulations, mode: mode, stage: stage);

  void reset() {
    _currentBallLevel = _randomBallLevel();
    _followingBallLevel = _randomBallLevel();
    _isDropReady = true;
    _publish(phase: GamePhase.modeSelect);
  }

  void dispose() => state.dispose();

  int _randomBallLevel() => _random.nextInt(2) + 1;

  void _publish({required GamePhase phase, GameMode? mode, Stage? stage}) {
    state.value = GameState(
      phase: phase,
      mode: mode,
      stage: stage,
      nextBallLevel: _currentBallLevel,
    );
  }
}

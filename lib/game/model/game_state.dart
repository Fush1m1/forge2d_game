import 'game_mode.dart';
import 'game_phase.dart';

class GameState {
  const GameState({
    required this.phase,
    this.mode,
    required this.nextBallLevel,
  });

  const GameState.modeSelect()
    : this(phase: GamePhase.modeSelect, nextBallLevel: 1);

  final GamePhase phase;
  final GameMode? mode;
  final int nextBallLevel;
}

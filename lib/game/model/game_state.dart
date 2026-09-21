import 'game_mode.dart';
import 'game_phase.dart';
import 'stage.dart';

class GameState {
  const GameState({
    required this.phase,
    this.mode,
    this.stage,
    required this.nextBallLevel,
  });

  const GameState.modeSelect()
    : this(phase: GamePhase.modeSelect, nextBallLevel: 1);

  final GamePhase phase;
  final GameMode? mode;
  final Stage? stage;
  final int nextBallLevel;
}

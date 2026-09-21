import 'package:flame_audio/flame_audio.dart';

import 'config/game_constants.dart';
import 'services/app_settings.dart';

/// Owns the merge sound's [AudioPool] (needs prewarming for rapid repeat
/// plays) and plays all three gameplay sound effects at the current volume
/// from [AppSettings].
class GameAudio {
  GameAudio(this.appSettings);

  final AppSettings appSettings;
  late final AudioPool _mergePool;

  Future<void> load() async {
    await FlameAudio.audioCache.loadAll([
      gameOverSoundFile,
      congratulationsSoundFile,
    ]);
    _mergePool = await FlameAudio.createPool(
      mergeSoundFile,
      minPlayers: 2,
      maxPlayers: 4,
    );
  }

  void playMerge() =>
      _mergePool.start(volume: appSettings.state.value.soundVolume);

  void playGameOver() => FlameAudio.play(
    gameOverSoundFile,
    volume: appSettings.state.value.soundVolume,
  );

  void playCongratulations() => FlameAudio.play(
    congratulationsSoundFile,
    volume: appSettings.state.value.soundVolume,
  );

  void dispose() => _mergePool.dispose();
}

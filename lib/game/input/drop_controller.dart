import '../model/game_mode.dart';

class DropController {
  static const _burstInterval = 0.15;
  static const _longPressThreshold = 0.5;
  static const _maxBurstCount = 10;

  bool _isHolding = false;
  int _burstCount = 0;
  double _burstTimer = 0;
  double _pressDuration = 0;

  void beginPress() {
    _isHolding = true;
    _burstCount = 0;
    _burstTimer = 0;
    _pressDuration = 0;
  }

  void endPress() => _isHolding = false;

  void recordInitialDrop() => _burstCount = 1;

  bool update(double dt, GameMode? mode) {
    if (mode != GameMode.easy || !_isHolding || _burstCount >= _maxBurstCount) {
      return false;
    }
    _pressDuration += dt;
    if (_pressDuration < _longPressThreshold) return false;

    _burstTimer += dt;
    if (_burstTimer < _burstInterval) return false;

    _burstTimer = 0;
    _burstCount++;
    return true;
  }
}

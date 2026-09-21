/// Converts raw accelerometer readings into a smoothed horizontal gravity
/// value, so that tilting the device rolls the balls left/right.
class TiltController {
  static const double _sensitivity = 1.6;
  static const double _smoothing = 0.2;
  static const double _maxHorizontalGravity = 20;

  double _horizontalGravity = 0;

  double get horizontalGravity => _horizontalGravity;

  /// [accelerometerX] is the device's local x-axis accelerometer reading
  /// (m/s^2, gravity included). The accelerometer measures the reaction to
  /// gravity rather than gravity itself, so the sign is flipped here to make
  /// tilting the right edge down roll the balls to the right.
  void update(double accelerometerX) {
    final target = (-accelerometerX * _sensitivity).clamp(
      -_maxHorizontalGravity,
      _maxHorizontalGravity,
    );
    _horizontalGravity += (target - _horizontalGravity) * _smoothing;
  }

  void reset() => _horizontalGravity = 0;
}

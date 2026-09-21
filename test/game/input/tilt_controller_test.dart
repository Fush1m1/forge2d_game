import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/input/tilt_controller.dart';

void main() {
  test('flat device produces no horizontal gravity', () {
    final controller = TiltController()..update(0);

    expect(controller.horizontalGravity, 0);
  });

  test('tilting the right edge down rolls balls to the right', () {
    final controller = TiltController();

    for (var i = 0; i < 60; i++) {
      controller.update(-9.8);
    }

    expect(controller.horizontalGravity, greaterThan(0));
  });

  test('tilting the left edge down rolls balls to the left', () {
    final controller = TiltController();

    for (var i = 0; i < 60; i++) {
      controller.update(9.8);
    }

    expect(controller.horizontalGravity, lessThan(0));
  });

  test('horizontal gravity is clamped to a sane maximum', () {
    final controller = TiltController();

    for (var i = 0; i < 200; i++) {
      controller.update(-100);
    }

    expect(controller.horizontalGravity, lessThanOrEqualTo(20));
  });

  test('reset clears any accumulated tilt', () {
    final controller = TiltController();
    for (var i = 0; i < 60; i++) {
      controller.update(-9.8);
    }

    controller.reset();

    expect(controller.horizontalGravity, 0);
  });
}

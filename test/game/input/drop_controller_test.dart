import 'package:flutter_test/flutter_test.dart';
import 'package:forge2d_game/game/input/drop_controller.dart';
import 'package:forge2d_game/game/model/game_mode.dart';

void main() {
  test('normal mode never emits burst drops', () {
    final controller = DropController()..beginPress();

    expect(controller.update(2, GameMode.normal), isFalse);
  });

  test('easy mode emits after the long-press threshold and interval', () {
    final controller =
        DropController()
          ..beginPress()
          ..recordInitialDrop();

    expect(controller.update(0.49, GameMode.easy), isFalse);
    expect(controller.update(0.01, GameMode.easy), isFalse);
    expect(controller.update(0.15, GameMode.easy), isTrue);
  });

  test('ending a press stops burst drops', () {
    final controller =
        DropController()
          ..beginPress()
          ..endPress();

    expect(controller.update(1, GameMode.easy), isFalse);
  });
}

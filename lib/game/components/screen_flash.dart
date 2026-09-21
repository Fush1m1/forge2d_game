import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../config/game_constants.dart';

/// A brief full-screen white flash, used to punctuate a dramatic moment
/// (e.g. an extra strong shake) with a camera-flash-like pop.
class ScreenFlashComponent extends RectangleComponent {
  ScreenFlashComponent()
    : super(paint: Paint()..color = Colors.white, priority: 1 << 20);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: screenFlashDuration, curve: Curves.easeOut),
        onComplete: removeFromParent,
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }
}

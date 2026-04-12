import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/utils/state_parameter.dart';

class EasyModeMessageComponent extends PositionComponent with TapCallbacks {
  EasyModeMessageComponent()
    : super(anchor: Anchor.centerLeft, size: Vector2(250, 60));

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 16.0,
      color: Colors.red,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1)),
      ],
    ),
  );

  bool isVisible = true;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // 画面中央左に配置
    position = Vector2(20, size.y / 2);
  }

  @override
  void render(Canvas canvas) {
    if (isVisible && isEasyMode) {
      _textPaint.render(
        canvas,
        'this is easy mode.\nyou can long press to burst.',
        Vector2.zero(),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    isVisible = !isVisible;
    event.handled = true;
  }
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DebugInfo {
  static final List<String> _messages = [];

  static void add(String message) {
    _messages.add(message);
  }

  static void clear() {
    _messages.clear();
  }

  static List<String> get messages => _messages;
}

class DebugInfoComponent extends PositionComponent {
  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 14.0,
      color: Colors.white,
      backgroundColor: Colors.black54,
    ),
  );

  @override
  void render(Canvas canvas) {
    final messages = DebugInfo.messages;
    for (var i = 0; i < messages.length; i++) {
      _textPaint.render(canvas, messages[i], Vector2(10, 10 + i * 20));
    }
  }

  @override
  void update(double dt) {
    // This ensures the debug info is fresh every frame.
    DebugInfo.clear();
  }
}

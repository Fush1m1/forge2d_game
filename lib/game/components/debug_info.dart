import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../suika_game.dart';

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

/// Toggleable debug log overlay. Tapping it shows/hides the log lines
/// (Obj Height, Threshold, Ball count, last tap). In debug builds it also
/// grows three extra tappable rows below the log: two to jump straight to
/// the Game Over / Congratulations overlays, and one to reset the
/// remembered Jev password authentication, so all three can be re-tested
/// without having to actually lose/win a round or clear all app data.
class DebugInfoComponent extends PositionComponent
    with TapCallbacks, HasGameReference<SuikaGame> {
  DebugInfoComponent() : super(size: Vector2(220, 170));

  static const double _lineHeight = 20;
  static const double _top = 10;
  static const double _left = 10;

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 14.0,
      color: Colors.white,
      backgroundColor: Colors.black54,
    ),
  );

  final TextPaint _buttonPaint = TextPaint(
    style: const TextStyle(
      fontSize: 14.0,
      color: Colors.yellowAccent,
      backgroundColor: Colors.black54,
    ),
  );

  bool isVisible = false;

  double get _gameOverButtonTop =>
      _top + DebugInfo.messages.length * _lineHeight + _lineHeight / 2;

  double get _congratulationsButtonTop => _gameOverButtonTop + _lineHeight;

  double get _resetJevAuthButtonTop => _congratulationsButtonTop + _lineHeight;

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    final messages = DebugInfo.messages;
    for (var i = 0; i < messages.length; i++) {
      _textPaint.render(
        canvas,
        messages[i],
        Vector2(_left, _top + i * _lineHeight),
      );
    }
    if (kDebugMode) {
      _buttonPaint.render(
        canvas,
        '[ Show Game Over ]',
        Vector2(_left, _gameOverButtonTop),
      );
      _buttonPaint.render(
        canvas,
        '[ Show Congratulations ]',
        Vector2(_left, _congratulationsButtonTop),
      );
      _buttonPaint.render(
        canvas,
        '[ Reset Jev Auth ]',
        Vector2(_left, _resetJevAuthButtonTop),
      );
    }
  }

  @override
  void update(double dt) {
    // This ensures the debug info is fresh every frame.
    DebugInfo.clear();
  }

  @override
  void onTapDown(TapDownEvent event) {
    event.handled = true;
    if (kDebugMode && isVisible) {
      final tapY = event.localPosition.y;
      if (tapY >= _gameOverButtonTop &&
          tapY < _gameOverButtonTop + _lineHeight) {
        game.debugShowGameOver();
        return;
      }
      if (tapY >= _congratulationsButtonTop &&
          tapY < _congratulationsButtonTop + _lineHeight) {
        game.debugShowCongratulations();
        return;
      }
      if (tapY >= _resetJevAuthButtonTop &&
          tapY < _resetJevAuthButtonTop + _lineHeight) {
        game.debugResetJevAuthentication();
        return;
      }
    }
    isVisible = !isVisible;
  }
}

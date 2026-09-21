import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

import '../config/game_constants.dart';

/// A short glowing burst played where two balls combine: a filled glow plus
/// an expanding ring, both growing and fading out. Higher-level merges get a
/// bigger, brighter, longer-lived burst so late-game combines feel more
/// rewarding.
class MergeBurstComponent extends PositionComponent {
  MergeBurstComponent({
    required Vector2 position,
    required double ballSize,
    required int level,
    double scaleBoost = mergeBurstScaleBoost,
  }) : _ballSize = ballSize,
       _scaleBoost = scaleBoost,
       _intensity = ((level - mergeBurstMinLevel) /
               (mergeBurstMaxLevel - mergeBurstMinLevel))
           .clamp(0, 1),
       super(position: position, anchor: Anchor.center);

  final double _ballSize;
  final double _scaleBoost;
  final double _intensity;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final duration =
        mergeBurstBaseDuration + _intensity * mergeBurstDurationBoost;
    final color =
        Color.lerp(mergeBurstColorLow, mergeBurstColorHigh, _intensity)!;
    final scale = mergeBurstBaseScale + _intensity * _scaleBoost;

    final glow = CircleComponent(
      radius: _ballSize / 2,
      anchor: Anchor.center,
      paint: Paint()..color = color.withValues(alpha: 0.8),
    )..addAll([
      ScaleEffect.to(
        Vector2.all(scale * 0.7),
        EffectController(duration: duration, curve: Curves.easeOut),
      ),
      OpacityEffect.fadeOut(
        EffectController(duration: duration, curve: Curves.easeIn),
      ),
    ]);

    final ring = CircleComponent(
      radius: _ballSize / 2,
      anchor: Anchor.center,
      paint:
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = _ballSize * 0.08,
    )..addAll([
      ScaleEffect.to(
        Vector2.all(scale),
        EffectController(duration: duration, curve: Curves.easeOut),
      ),
      OpacityEffect.fadeOut(
        EffectController(duration: duration, curve: Curves.easeIn),
      ),
    ]);

    addAll([glow, ring, RemoveEffect(delay: duration)]);
  }
}

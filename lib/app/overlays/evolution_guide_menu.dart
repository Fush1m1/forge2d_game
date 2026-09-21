import 'dart:math' as math;

import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/model/ball_definition.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Shows every ball level arranged in a ring ("進化の輪"), from level 1 at
/// the top going clockwise to level 10, connected by arrows so players can
/// see the whole evolution chain and its direction at a glance.
class EvolutionGuideMenu extends StatelessWidget {
  final SuikaGame game;

  const EvolutionGuideMenu({super.key, required this.game});

  static const int _minLevel = 1;
  static const int _maxLevel = 10;
  static const double _minIconSize = 26;
  static const double _maxIconSize = 46;
  static const double _minDiameter = 25;
  static const double _maxDiameter = 200;
  static const double _ringMargin = 12;

  static double _angleFor(int level) =>
      2 * math.pi * (level - _minLevel) / (_maxLevel - _minLevel + 1) -
      math.pi / 2;

  static double _iconSizeFor(int level) {
    final definition = BallDefinition.forLevel(level);
    final sizeT = ((definition.diameter - _minDiameter) /
            (_maxDiameter - _minDiameter))
        .clamp(0, 1);
    return _minIconSize + sizeT * (_maxIconSize - _minIconSize);
  }

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 360,
        height: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.overlayBackground.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: AppTheme.overlayBorder,
            width: AppTheme.borderWidth / 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text(
                  '進化の輪',
                  style: TextStyle(
                    color: AppTheme.titleText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  onPressed: game.closeEvolutionGuide,
                  icon: const Icon(Icons.close, color: AppTheme.shadowColor),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final diameter = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final ringRadius =
                      diameter / 2 - _maxIconSize / 2 - _ringMargin;
                  return SizedBox(
                    width: diameter,
                    height: diameter,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.overlayBorder,
                              width: 2,
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: Size.square(diameter),
                          painter: _EvolutionArrowsPainter(
                            ringRadius: ringRadius,
                            color: AppTheme.buttonBackground,
                          ),
                        ),
                        for (var level = _minLevel; level <= _maxLevel; level++)
                          _positionedBall(
                            game: game,
                            level: level,
                            ringDiameter: diameter,
                            ringRadius: ringRadius,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: game.closeEvolutionGuide,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Center(child: card),
      ],
    );
  }

  static Widget _positionedBall({
    required SuikaGame game,
    required int level,
    required double ringDiameter,
    required double ringRadius,
  }) {
    final definition = BallDefinition.forLevel(level);
    final iconSize = _iconSizeFor(level);
    final angle = _angleFor(level);
    final center = ringDiameter / 2;
    final left = center + ringRadius * math.cos(angle) - iconSize / 2;
    final top = center + ringRadius * math.sin(angle) - iconSize / 2;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: SpriteWidget(
          sprite: game.aliens.getSprite(definition.spriteName),
        ),
      ),
    );
  }
}

/// Draws a short clockwise arc with an arrowhead between every pair of
/// adjacent levels, so the direction of evolution (level N -> level N+1) is
/// visually obvious around the ring.
class _EvolutionArrowsPainter extends CustomPainter {
  _EvolutionArrowsPainter({required this.ringRadius, required this.color});

  final double ringRadius;
  final Color color;

  static const double _arrowLength = 8;
  static const double _arrowWidth = 7;
  static const double _iconGap = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..color = color;

    for (
      var level = EvolutionGuideMenu._minLevel;
      level < EvolutionGuideMenu._maxLevel;
      level++
    ) {
      final startGap =
          (EvolutionGuideMenu._iconSizeFor(level) / 2 + _iconGap) / ringRadius;
      final endGap =
          (EvolutionGuideMenu._iconSizeFor(level + 1) / 2 + _iconGap) /
          ringRadius;
      final startAngle = EvolutionGuideMenu._angleFor(level) + startGap;
      final endAngle = EvolutionGuideMenu._angleFor(level + 1) - endGap;
      final sweep = endAngle - startAngle;
      if (sweep <= 0.02) continue;

      final path =
          Path()..addArc(
            Rect.fromCircle(center: center, radius: ringRadius),
            startAngle,
            sweep,
          );
      canvas.drawPath(path, strokePaint);

      final tip =
          center + Offset(math.cos(endAngle), math.sin(endAngle)) * ringRadius;
      final forward = Offset(-math.sin(endAngle), math.cos(endAngle));
      final perpendicular = Offset(-forward.dy, forward.dx);
      final base = tip - forward * _arrowLength;
      final left = base + perpendicular * (_arrowWidth / 2);
      final right = base - perpendicular * (_arrowWidth / 2);

      final arrowHead =
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
      canvas.drawPath(arrowHead, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvolutionArrowsPainter oldDelegate) =>
      oldDelegate.ringRadius != ringRadius || oldDelegate.color != color;
}

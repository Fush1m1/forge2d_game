import 'dart:math' as math;

import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forge2d_game/app/theme/app_theme.dart';
import 'package:forge2d_game/game/model/ball_definition.dart';
import 'package:forge2d_game/game/suika_game.dart';

/// Shows every ball level arranged in a ring ("進化の輪"), from level 1 at
/// the top going clockwise to level 10, so players can see the whole
/// evolution chain at a glance.
class EvolutionGuideMenu extends StatelessWidget {
  final SuikaGame game;

  const EvolutionGuideMenu({super.key, required this.game});

  static const int _minLevel = 1;
  static const int _maxLevel = 10;
  static const double _minIconSize = 28;
  static const double _maxIconSize = 52;
  static const double _minDiameter = 25;
  static const double _maxDiameter = 200;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 340,
          height: 400,
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
                          for (
                            var level = _minLevel;
                            level <= _maxLevel;
                            level++
                          )
                            _positionedBall(
                              game: game,
                              level: level,
                              ringDiameter: diameter,
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
      ),
    );
  }

  static Widget _positionedBall({
    required SuikaGame game,
    required int level,
    required double ringDiameter,
  }) {
    final definition = BallDefinition.forLevel(level);
    final sizeT = ((definition.diameter - _minDiameter) /
            (_maxDiameter - _minDiameter))
        .clamp(0, 1);
    final iconSize = _minIconSize + sizeT * (_maxIconSize - _minIconSize);

    final angle =
        2 * math.pi * (level - _minLevel) / (_maxLevel - _minLevel + 1) -
        math.pi / 2;
    final center = ringDiameter / 2;
    final radius = center - iconSize / 2 - 16;
    final left = center + radius * math.cos(angle) - iconSize / 2;
    final top = center + radius * math.sin(angle) - iconSize / 2 - 8;

    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: SpriteWidget(
              sprite: game.aliens.getSprite(definition.spriteName),
            ),
          ),
          Text(
            '$level',
            style: const TextStyle(
              color: AppTheme.shadowColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

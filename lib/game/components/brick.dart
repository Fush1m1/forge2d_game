import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d_game/game/config/game_constants.dart';
import 'package:forge2d_game/shared/forge2d/body_component_with_user_data.dart';

enum BrickType {
  explosive(density: 1, friction: 0.5),
  glass(density: 0.5, friction: 0.2),
  metal(density: 1, friction: 0.4),
  stone(density: 2, friction: 1),
  wood(density: 0.25, friction: 0.6);

  final double density;
  final double friction;

  const BrickType({required this.density, required this.friction});
  static BrickType get randomType => values[Random().nextInt(values.length)];
}

enum BrickSize {
  size70x70(ui.Size(70, 70)),
  size140x70(ui.Size(140, 70)),
  size220x70(ui.Size(220, 70)),
  size70x140(ui.Size(70, 140)),
  size140x140(ui.Size(140, 140)),
  size220x140(ui.Size(220, 140)),
  size140x220(ui.Size(140, 220)),
  size70x220(ui.Size(70, 220));

  final ui.Size size;

  const BrickSize(this.size);

  static BrickSize get randomSize => values[Random().nextInt(values.length)];
}

enum BrickDamage { none, some, lots }

class Brick extends BodyComponentWithUserData {
  Brick({
    required this.type,
    required this.size,
    required BrickDamage damage,
    required Vector2 position,
    required Map<BrickDamage, Sprite> sprites,
    double angle = 0,
  }) : _damage = damage,
       _sprites = sprites,
       super(
         renderBody: false,
         bodyDef:
             BodyDef()
               ..position = position
               ..angle = angle
               ..type = BodyType.static,
         fixtureDefs: [
           FixtureDef(
               PolygonShape()..setAsBoxXY(
                 size.size.width / 20 * brickScale,
                 size.size.height / 20 * brickScale,
               ),
             )
             ..restitution = 0.4
             ..density = type.density
             ..friction = type.friction,
         ],
       );

  late final SpriteComponent _spriteComponent;

  final BrickType type;
  final BrickSize size;
  final Map<BrickDamage, Sprite> _sprites;

  BrickDamage _damage;
  BrickDamage get damage => _damage;
  set damage(BrickDamage value) {
    _damage = value;
    _spriteComponent.sprite = _sprites[value];
  }

  @override
  Future<void> onLoad() {
    _spriteComponent = SpriteComponent(
      anchor: Anchor.center,
      scale: Vector2.all(1),
      sprite: _sprites[_damage],
      size: size.size.toVector2() / 10 * brickScale,
      position: Vector2(0, 0),
    );
    add(_spriteComponent);
    return super.onLoad();
  }
}

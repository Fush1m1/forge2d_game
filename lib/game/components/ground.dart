import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d_game/game/config/game_constants.dart';
import 'package:forge2d_game/shared/forge2d/body_component_with_user_data.dart';

class Ground extends BodyComponentWithUserData {
  Ground(Vector2 position, Sprite sprite)
    : super(
        renderBody: false,
        bodyDef:
            BodyDef()
              ..position = position
              ..type = BodyType.static,
        fixtureDefs: [
          FixtureDef(
            PolygonShape()..setAsBoxXY(groundTileSize / 2, groundTileSize / 2),
            friction: 0.3,
          ),
        ],
        children: [
          SpriteComponent(
            anchor: Anchor.center,
            sprite: sprite,
            size: Vector2.all(groundTileSize),
            position: Vector2(0, 0),
          ),
        ],
      );
}

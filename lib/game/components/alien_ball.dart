import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:forge2d_game/game/config/game_constants.dart';
import 'package:forge2d_game/game/suika_game.dart';

class AlienBall extends PositionComponent
    with HasGameReference<SuikaGame>, ContactCallbacks {
  late final SpriteComponent spriteComponent;
  late final BodyComponent bodyComponent;
  final Vector2 posi;
  final int number;
  final double ballSize;
  final double speed;

  bool hasFirstCollisionExecuted;

  bool isSpriteLoaded = false;

  AlienBall({
    required this.posi,
    required this.number,
    required this.ballSize,
    required this.speed,
    required this.hasFirstCollisionExecuted,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadSprite();
    _createBody();
    add(spriteComponent);
    add(bodyComponent);
  }

  bool hasCombined = false;
  double timeElapsed = 0.0;
  void _loadSprite() {
    final spriteName = game.ballDefinitionFor(number).spriteName;
    spriteComponent =
        SpriteComponent()
          ..sprite = game.aliens.getSprite(spriteName)
          ..anchor = Anchor.center
          ..size = Vector2.all(ballSize);
    isSpriteLoaded = true;
  }

  void _createBody() {
    bodyComponent = BallBody(
      parentball: this,
      posi: posi,
      ballSize: ballSize,
      speed: speed,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isSpriteLoaded) {
      spriteComponent.position = bodyComponent.body.position;
      spriteComponent.angle = bodyComponent.body.angle;
    }
    if (hasFirstCollisionExecuted) {
      if (bodyComponent.body.position.y + ballSize / 2 <= dropLineY) {
        timeElapsed += dt;
        if (timeElapsed > collisionSettleDuration) {
          timeElapsed = 0.0;
        }
      } else {
        timeElapsed = 0;
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (!hasFirstCollisionExecuted) {
      hasFirstCollisionExecuted = true;
      game.onBallCollision(other);
    }
    if (other is AlienBall) {
      if (other.number == number && !other.hasCombined && !hasCombined) {
        game.requestMerge(this, other);
      }
    }
  }
}

class BallBody extends BodyComponent with ContactCallbacks {
  final AlienBall parentball;
  final Vector2 posi;
  final double ballSize;
  final double speed;
  BallBody({
    required this.parentball,
    required this.posi,
    required this.ballSize,
    required this.speed,
  }) {
    opacity = 0.0;
  }
  @override
  Body createBody() {
    final shape = CircleShape()..radius = (ballSize) / 2;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.05,
      density: 120.0,
      friction: 0.1,
    );
    final bodyDef = BodyDef(
      userData: parentball,
      linearVelocity: Vector2(0, speed),
      position: posi,
      linearDamping: 0.1,
      angularDamping: 0.3,
      type: BodyType.dynamic,
    );
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

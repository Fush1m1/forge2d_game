import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/config.dart';


class AlienBall extends PositionComponent
    with HasGameReference<SuikaGame>, ContactCallbacks, CollisionCallbacks {
  late final SpriteComponent spriteComponent;
  late final BodyComponent bodyComponent;
  final Vector2 posi;
  int number;
  double ballSize;
  double speed;

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
    String spriteName = getAlienSpriteName(number);
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
      if (bodyComponent.body.position.y + ballSize / 2 <= lineY * heightPer) {
        timeElapsed += dt;
        if (timeElapsed > certainTime) {
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
      game.onballCollision();
    }
    if (other is AlienBall) {
      if (other.number == number && !other.hasCombined && !hasCombined) {
        Vector2 newPosition =
            (other.bodyComponent.body.position + bodyComponent.body.position) /
            2;
        hasCombined = true;
        other.hasCombined = true;
        if (number < 9) {
          game.ballToRemove.add(other);
          game.ballToRemove.add(this);
          int newNumber = number + 1;
          game.ballToAdd.add(
            AlienBall(
              posi: newPosition,
              number: newNumber,
              ballSize: calcTypeSize(newNumber, allPer),
              speed: 0.0,
              // 新規作成されるボールは常に衝突済みとする
              hasFirstCollisionExecuted: true,
            ),
          );
        }
      }
    }
  }
}

class BallBody extends BodyComponent with ContactCallbacks {
  final AlienBall parentball;
  final Vector2 posi;
  double ballSize;
  double speed;
  BallBody({
    required this.parentball,
    required this.posi,
    required this.ballSize,
    required this.speed,
  }) {
    opacity = 0.0;
  }
  bool onGround = false;
  bool onBar = false;
  double prePositionY = 0;
  double timeElapsed = 0.0;
  double certainTime = 1.0;
  bool hasCombined = false;
  String strImage = "";
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

double calcTypeSize(int number, double per) {
  switch (number) {
    case 1:
      return 25.0 / scale * per;
    case 2:
      return 30.0 / scale * per;
    case 3:
      return 35.0 / scale * per;
    case 4:
      return 45.0 / scale * per;
    case 5:
      return 60.0 / scale * per;
    case 6:
      return 80.0 / scale * per;
    case 7:
      return 100.0 / scale * per;
    case 8:
      return 120.0 / scale * per;
    case 9:
      return 150.0 / scale * per;

    default:
      return 0;
  }
}

String getAlienSpriteName(int number) {
  switch (number) {
    case 1:
      return 'alienBeige_round.png';
    case 2:
      return 'alienBlue_round.png';
    case 3:
      return 'alienGreen_round.png';
    case 4:
      return 'alienPink_round.png';
    case 5:
      return 'alienYellow_round.png';
    case 6:
      return 'alienBeige_suit.png';
    case 7:
      return 'alienBlue_suit.png';
    case 8:
      return 'alienGreen_suit.png';
    case 9:
      return 'alienPink_suit.png';
    
    default:
      return 'alienBeige_round.png';
  }
}

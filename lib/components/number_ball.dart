import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:forge2d_game/game.dart';
import 'package:forge2d_game/utils/config.dart';

final List<NumberBall> ballToRemove = [];
final List<NumberBall> ballToAdd = [];

class NumberBall extends PositionComponent
    with HasGameReference<SuikaGame>, ContactCallbacks, CollisionCallbacks {
  late final SpriteComponent spriteComponent;
  late final BodyComponent bodyComponent;
  final Vector2 posi;
  int number;
  double ballSize;
  double speed;

  bool hasFirstCollisionExecuted;

  bool isSpriteLoaded = false;

  NumberBall({
    required this.posi,
    required this.number,
    required this.ballSize,
    required this.speed,
    required this.hasFirstCollisionExecuted,
  }) {
    String strImage = getImagePNG(number);
    _loadSprite(strImage).then((_) {
      _createBody();
      add(spriteComponent);
      add(bodyComponent);
    });
  }
  bool hasCombined = false;
  double timeElapsed = 0.0;
  Future<void> _loadSprite(String imagePath) async {
    spriteComponent =
        SpriteComponent()
          ..sprite = await Sprite.load(imagePath)
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
    if (other is NumberBall) {
      if (other.number == number && !other.hasCombined && !hasCombined) {
        Vector2 newPosition =
            (other.bodyComponent.body.position + bodyComponent.body.position) /
            2;
        hasCombined = true;
        other.hasCombined = true;
        if (number < 3) {
          ballToRemove.add(other);
          ballToRemove.add(this);
          int newNumber = number + 1;
          ballToAdd.add(
            NumberBall(
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
  final NumberBall parentball;
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
    default:
      return 0;
  }
}

String getImagePNG(int number) {
  String strImage = '';
  switch (number) {
    case 1:
      strImage = '01.png';
      break;
    case 2:
      strImage = '02.png';
      break;
    case 3:
      strImage = '03.png';
      break;
    default:
  }
  return strImage;
}

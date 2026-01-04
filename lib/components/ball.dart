import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'package:forge2d_game/components/game.dart';
import 'package:forge2d_game/config.dart';

final List<Ball> ballToRemove = [];
final List<Ball> ballToAdd = [];
List<Ball> allballs = [];

class Ball extends PositionComponent
    with HasGameReference<SuikaGame>, ContactCallbacks, CollisionCallbacks {
  late final SpriteComponent spriteComponent;
  late final BodyComponent bodyComponent;
  final Vector2 posi;
  int type;
  double typeSize;
  double hitSize;
  double speed;

  /// この ball が「初めて何かに接触したか」を示す状態フラグ。
  ///
  /// ## 役割
  /// - 生成直後（落下中）の ball と、
  ///   何かに接触して設置された ball を区別するために使用する。
  /// - ゲーム進行・入力制御・合体判定の起点となる重要なフラグ。
  ///
  /// ## 状態遷移
  /// - false :
  ///   - 生成直後の状態
  ///   - プレイヤーがタップして落下中の ball
  ///   - まだ床や他の ball に接触していない
  /// - true :
  ///   - 下のバー（underBar）または他の ball に初めて接触した後
  ///   - 設置済みとみなされ、合体判定が有効になる
  ///
  /// ## 使用箇所と目的
  /// 1. 入力制御:
  ///    - 落下中（firstTouch == false）は次の ball を生成させない
  ///    - 初回接触時に tapOK を true に戻し、次のタップを許可する
  ///
  /// 2. 合体制御:
  ///    - 落下中の ball が空中で即座に合体するのを防ぐ
  ///    - 設置後のみ同種 ball との合体を許可する
  ///
  /// 3. 物理安定化:
  ///    - 空中での一時的な重なりによる誤判定を防止する
  ///
  /// ## 注意点
  /// - 初回接触時のみ true に遷移し、
  ///   一度 true になった後は false に戻さない
  /// - 合体によって生成される ball は、
  ///   すでに設置済みとして扱うため true で初期化する
  bool firstTouch;

  bool isSpriteLoaded = false;

  Ball({
    required this.posi,
    required this.type,
    required this.typeSize,
    required this.hitSize,
    required this.speed,
    required this.firstTouch,
  }) {
    String strImage = getImagePNG(type);
    _loadSprite(strImage).then((_) {
      allballs.add(this);
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
          ..size = Vector2.all(typeSize);
    isSpriteLoaded = true;
  }

  void _createBody() {
    bodyComponent = BallBody(
      parentball: this,
      posi: posi,
      type: type,
      typeSize: typeSize,
      hitSize: hitSize,
      speed: speed,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isSpriteLoaded) {
      if (isSpriteLoaded) {
        spriteComponent.position = bodyComponent.body.position;
        spriteComponent.angle = bodyComponent.body.angle;
      }
    }
    if (firstTouch) {
      if (bodyComponent.body.position.y + hitSize / 2 <= lineY * heightPer) {
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
  void onRemove() {
    super.onRemove();
    allballs.remove(this);
  }

  @override
  void beginContact(Object other, Contact contact) {
    int newType = 1;
    double newSize = 10.0;
    double newHitSize = 10.0;
    if (!firstTouch) {
      firstTouch = true;
      game.onballCollision();
    }
    if (other is Ball) {
      if (other.type == type && !other.hasCombined && !hasCombined) {
        Vector2 newPosition =
            (other.bodyComponent.body.position + bodyComponent.body.position) /
            2;
        hasCombined = true;
        other.hasCombined = true;
        if (type < 3) {
          ballToRemove.add(other);
          ballToRemove.add(this);
          newType = type + 1;
          newSize = calcTypeSize(newType, allPer);
          newHitSize = newSize;
          ballToAdd.add(
            Ball(
              posi: newPosition,
              type: newType,
              typeSize: newSize,
              hitSize: newHitSize,
              speed: 0.0,
              firstTouch: true,
            ),
          );
        }
      }
    }
  }
}

class BallBody extends BodyComponent with ContactCallbacks {
  final Ball parentball;
  final Vector2 posi;
  int type;
  double typeSize;
  double hitSize;
  double speed;
  BallBody({
    required this.parentball,
    required this.posi,
    required this.type,
    required this.typeSize,
    required this.hitSize,
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
    final shape = CircleShape()..radius = (hitSize) / 2;
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

double calcTypeSize(int type, double per) {
  double typeSize = 0.0;
  switch (type) {
    case 1:
      typeSize = 25.0 / scale * per;
      break;
    case 2:
      typeSize = 30.0 / scale * per;
      break;
    case 3:
      typeSize = 35.0 / scale * per;
      break;
    default:
  }
  return typeSize;
}

String getImagePNG(int type) {
  String strImage = '';
  switch (type) {
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

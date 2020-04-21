import 'package:batufo/shared/dart_types/dart_types.dart';
import 'package:batufo/shared/engine/geometry/dart_geometry.dart' show Offset;
import 'package:batufo/shared/engine/tile_position.dart';

class BulletModel {
  TilePosition tilePosition;
  Offset velocity;
  bool collided;

  BulletModel({
    @required this.tilePosition,
    @required this.velocity,
    this.collided = false,
  });

  BulletModel clone() {
    return BulletModel(
      tilePosition: tilePosition.copyWith(),
      velocity: Offset(velocity.dx, velocity.dy),
    );
  }

  String toString() {
    return 'BulletModel [ $tilePosition, $velocity, $collided ]';
  }
}

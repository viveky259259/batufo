import 'dart:math';
import 'dart:ui' show Canvas, Offset, Size;

import 'package:batufo/client/engine/game.dart';
import 'package:batufo/client/game/assets/assets.dart';
import 'package:batufo/client/game/entities/background.dart';
import 'package:batufo/client/game/entities/bullets.dart';
import 'package:batufo/client/game/entities/grid.dart';
import 'package:batufo/client/game/entities/player.dart';
import 'package:batufo/client/game/entities/walls.dart';
import 'package:batufo/client/game/inputs/gestures.dart';
import 'package:batufo/client/game/inputs/input_processor.dart';
import 'package:batufo/client/game/inputs/keyboard.dart';
import 'package:batufo/shared/arena/arena.dart';
import 'package:batufo/shared/controllers/game_controller.dart';
import 'package:batufo/shared/diagnostics/logger.dart';
import 'package:batufo/shared/engine/world_position.dart';
import 'package:batufo/shared/game_props.dart';
import 'package:batufo/shared/models/game_model.dart';
import 'package:batufo/shared/models/player_model.dart';

final _log = Log<ClientGame>();

class ClientGame extends Game {
  final ClientGameState _game;
  final Arena _arena;
  final Background _background;
  final Grid _grid;
  final Walls _walls;
  final GameController _gameController;
  final InputProcessor _inputProcessor;
  final int _clientID;

  Map<int, Player> _players;
  Bullets _bullets;

  Offset _camera;
  Offset _backgroundCamera;
  Size _size;

  ClientGame(this._arena, this._game, this._clientID)
      : _gameController = GameController(_arena, _game),
        _grid = Grid(GameProps.tileSize),
        _background = Background(
          _arena.floorTiles,
          GameProps.tileSize,
          GameProps.renderBackground,
        ),
        _walls = Walls(_arena.walls, GameProps.tileSize),
        _inputProcessor = InputProcessor(
          keyboardRotationFactor: GameProps.keyboardPlayerRotationFactor,
          keyboardThrustForce: GameProps.keyboardPlayerThrustForce,
        ),
        _camera = Offset.zero,
        _backgroundCamera = Offset.zero {
    _players = <int, Player>{};
    for (final clientID in _game.players.keys) {
      _players[clientID] = _initPlayer();
    }

    _bullets = Bullets(
      msToExplode: GameProps.bulletMsToExplode,
      tileSize: GameProps.tileSize,
    );
  }

  PlayerModel get clientPlayer {
    final player = _game.players[_clientID];
    assert(player != null, 'our player with id $_clientID should exist');
    return player;
  }

  void update(double dt, double ts) {
    final pressedKeys = GameKeyboard.pressedKeys;
    final gestures = GameGestures.instance.aggregatedGestures;

    _inputProcessor.udate(dt, pressedKeys, gestures, clientPlayer);
    // _gameController.update(dt, ts);
  }

  void updateUI(double dt, double ts) {
    _cameraFollow(
      clientPlayer.tilePosition.toWorldPosition(),
      dt,
    );
    for (final entry in _game.players.entries) {
      _players[entry.key].updateSprites(entry.value, dt);
    }
    _bullets.updateSprites(_game.bullets, dt);
  }

  void render(Canvas canvas) {
    _lowerLeftCanvas(canvas, _size.height);

    canvas.save();
    {
      canvas.translate(-_backgroundCamera.dx, -_backgroundCamera.dy);
      _grid.render(canvas, _arena.nrows, _arena.ncols);
    }
    canvas.restore();

    {
      canvas.translate(-_camera.dx, -_camera.dy);
      _background.render(canvas);
      _walls.render(canvas);
      for (final entry in _game.players.entries) {
        _log.finest('render ${entry.value.tilePosition}');
        _players[entry.key].render(canvas, entry.value);
      }
      _bullets.render(canvas, _game.bullets);
    }
  }

  void resize(Size size) {
    _size = size;
  }

  void _cameraFollow(WorldPosition wp, double dt) {
    if (_size == null) return;
    final pos = wp.toOffset();
    final centerScreen = Offset(_size.width / 2, _size.height / 2);
    final moved = Offset(pos.dx - centerScreen.dx, pos.dy - centerScreen.dy);

    final lerp = min(0.0025 * dt, 1.0);
    const backgroundLerp = 0.8;
    final dx = (moved.dx - _camera.dx) * lerp;
    final dy = (moved.dy - _camera.dy) * lerp;
    _camera = _camera.translate(dx, dy);
    _backgroundCamera = _backgroundCamera.translate(
      dx * backgroundLerp,
      dy * backgroundLerp,
    );
  }

  void _lowerLeftCanvas(Canvas canvas, double height) {
    canvas
      ..translate(0, height)
      ..scale(1, -1);
  }

  Player _initPlayer() {
    return Player(
      playerImagePath: assets.player.imagePath,
      tileSize: GameProps.tileSize,
      hitSize: GameProps.playerSize,
      thrustAnimationDurationMs: GameProps.playerThrustAnimationDurationMs,
    );
  }
}

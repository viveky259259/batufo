import 'dart:async';

import 'package:batufo/shared/controllers/game_controller.dart';
import 'package:batufo/shared/diagnostics/logger.dart';
import 'package:batufo/shared/messaging/player_inputs.dart';
import 'package:batufo/shared/models/game_state.dart';
import 'package:batufo/shared/models/player_model.dart';

const TICK_DURATION = 20;
const MESSAGING_INTERVAL_MS = 100.0;
final _log = Log<GameLoop>();

class GameLoop {
  bool _started;
  final GameController _gameController;
  double timeUntilNextMessage = 0;
  DateTime _lastTick;
  GameLoop(this._gameController) : _started = false;

  final _gameState$ = StreamController<GameState>.broadcast();
  Stream<GameState> get gameState$ => _gameState$.stream;

  void start(int gameID) {
    assert(!_started, 'cannot start the game loop twice');
    _log.info('starting gameloop $gameID');
    _started = true;
    _scheduleTick();
  }

  void addPlayer(PlayerModel player) {
    _gameController.addPlayer(player);
  }

  void syncPlayerInputs(int clientID, PlayerInputs inputs) {
    _gameController.syncPlayerInputs(clientID, inputs);
  }

  void _scheduleTick() {
    Future.delayed(Duration(milliseconds: TICK_DURATION), _tick);
  }

  void _tick() {
    final ts = DateTime.now();
    final double dt = _lastTick == null
        ? Duration.zero.inMicroseconds / 1E3
        : ts.difference(_lastTick).inMicroseconds / 1E3;

    final gameState = _gameController.update(
      dt,
      ts.microsecondsSinceEpoch / 1E3,
    );
    _lastTick = ts;

    _maybeSendGameState(gameState, dt);
    // TODO: send player thrust correctly so we see other players
    //
    //    applying thrust
    _gameController.cleanup();
    _scheduleTick();
  }

  void _maybeSendGameState(GameState gameState, double dt) {
    timeUntilNextMessage -= dt;
    if (timeUntilNextMessage > 0) {
      return;
    }

    _gameState$.add(gameState.clone());
    timeUntilNextMessage = MESSAGING_INTERVAL_MS;
  }

  void dispose() {
    if (!_gameState$.isClosed) _gameState$?.close();
  }
}

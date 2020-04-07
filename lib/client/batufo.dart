import 'dart:io';

import 'package:batufo/client/engine/game_widget.dart';
import 'package:batufo/client/engine/images.dart';
import 'package:batufo/client/game/assets/assets.dart';
import 'package:batufo/client/game/client_game.dart';
import 'package:batufo/client/game/inputs/gestures.dart';
import 'package:batufo/client/rpc/client.dart';
import 'package:batufo/shared/arena/arena.dart';
import 'package:batufo/shared/diagnostics/logger.dart';
import 'package:batufo/shared/engine/world_position.dart';
import 'package:batufo/shared/game_props.dart';
import 'package:batufo/shared/generated/message_bus.pb.dart'
    show GameStateEvent;
import 'package:batufo/shared/models/game_model.dart';
import 'package:batufo/shared/models/game_state.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  Log.activateConsole();
  Log.rootLevel = Level.FINEST;

  WidgetsFlutterBinding.ensureInitialized();
  await Images.instance.load([
    assets.floorTiles.imagePath,
    assets.player.imagePath,
    assets.thrust.imagePath,
    assets.wallMetal.imagePath,
    assets.bulletExplosion.imagePath,
  ]);
  const level = 'simple';
  final serverIP = Platform.isAndroid ? '192.168.1.7' : 'localhost';
  final client = await Client.create(level, serverIP);

  WorldPosition.tileSize = GameProps.tileSize;
  runApp(MyApp(
    arena: client.arena,
    clientGameState: ClientGameState(),
    gameStateEvent$: client.gameStateEvent$,
    clientID: client.clientID,
  ));
}

class MyApp extends StatefulWidget {
  final Stream<GameStateEvent> gameStateEvent$;
  final Arena arena;
  final ClientGameState clientGameState;
  final int clientID;

  const MyApp({
    @required this.arena,
    @required this.gameStateEvent$,
    @required this.clientGameState,
    @required this.clientID,
  }) : super();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ClientGame game;
  RunningGame gameWidget;

  ClientGameState get clientGameState => widget.clientGameState;

  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: StreamBuilder<GameStateEvent>(
          builder: _build,
          stream: widget.gameStateEvent$,
          initialData: null,
        )));
  }

  Widget _build(BuildContext context, AsyncSnapshot<GameStateEvent> snapshot) {
    if (snapshot.data == null) return WaitingForPlayers();
    final gameState = GameState.unpack(snapshot.data.gameState);
    if (game == null) {
      clientGameState.sync(gameState);
      game = ClientGame(widget.arena, widget.clientGameState, widget.clientID);
      gameWidget = RunningGame(game: game);
    } else {
      clientGameState.sync(gameState);
    }
    return gameWidget;
  }
}

class WaitingForPlayers extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(child: Text('Waiting for players'));
  }
}

class RunningGame extends StatelessWidget {
  final ClientGame game;
  const RunningGame({@required this.game});

  Widget build(BuildContext context) {
    return Stack(children: [
      GestureDetector(
        onPanUpdate: GameGestures.instance.onPanUpdate,
        child: GameWidget(
          game,
          background: Colors.tealAccent,
        ),
      ),
      /*
          StreamBuilder(
            stream: gameModel.stats.update$,
            builder: (_, AsyncSnapshot<StatsModel> snapshot) =>
                HudWidget(model: snapshot.data),
            initialData: gameModel.stats,
          )
           */
    ]);
  }
}
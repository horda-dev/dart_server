import 'package:horda_core/horda_core.dart';

typedef ActorInitHandler2<C extends RemoteCommand, E extends RemoteEvent>
    = Future<E> Function(
  C command,
  ActorContext2 context,
);

typedef ActorHandler2<S extends ActorState2, C extends RemoteCommand>
    = Future<RemoteEvent> Function(
  C command,
  S state,
  ActorContext2 context,
);

abstract class ActorHandlers2<S extends ActorState2> {
  void addInit<C extends RemoteCommand, E extends RemoteEvent>(
    ActorInitHandler2<C, E> handler,
    FromJsonFun<C> cmdFromJson,
    ActorStateInitProjector<E> stateInit,
  );
  void add<C extends RemoteCommand>(
    ActorHandler2<S, C> handler,
    FromJsonFun<C> fromJson,
  );
  void addStateFromJson(
    FromJsonFun<S> fromJson,
  );
}

/// Actor is a worker that process commands in FIFO order.
abstract class Actor2<S extends ActorState2> {
  String get name => runtimeType.toString();

  void initHandlers(ActorHandlers2<S> handlers);

  void initMigrations(ActorStateMigrations migrations);
}

abstract class ActorContext2 {
  /// Id of an actor that handles current command
  ActorId get actorId;

  /// Id of an actor or a flow that sent current command
  ActorId get senderId;

  DateTime get clock;

  // Logger get logger;

  Future<QueryResult2> query(ActorId actorId, QueryDef query);

  void stop();
}

typedef ActorStateInitProjector<E extends RemoteEvent> = ActorState2 Function(
  E event,
);

abstract class ActorState2 {
  void project(RemoteEvent event);

  Map<String, dynamic> toJson();
}

abstract class ActorStateMigrations {
  void add(ActorStateMigration migration);

  Map<String, dynamic> migrate(int fromVersion, Map<String, dynamic> fromState);

  int get latestVersion;
}

abstract class ActorStateMigration {
  Map<String, dynamic> migrate(Map<String, dynamic> from);

  int get version;
}

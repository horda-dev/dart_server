import 'package:horda_core/horda_core.dart';

typedef EntityInitHandler<C extends RemoteCommand, E extends RemoteEvent>
    = Future<E> Function(
  C command,
  EntityContext context,
);

typedef EntityHandler<S extends EntityState, C extends RemoteCommand>
    = Future<RemoteEvent> Function(
  C command,
  S state,
  EntityContext context,
);

abstract class EntityHandlers<S extends EntityState> {
  void addInit<C extends RemoteCommand, E extends RemoteEvent>(
    EntityInitHandler<C, E> handler,
    FromJsonFun<C> cmdFromJson,
    EntityStateInitProjector<E> stateInit,
  );
  void add<C extends RemoteCommand>(
    EntityHandler<S, C> handler,
    FromJsonFun<C> fromJson,
  );
  void addStateFromJson(
    FromJsonFun<S> fromJson,
  );
}

/// Actor is a worker that process commands in FIFO order.
abstract class Entity<S extends EntityState> {
  String get name => runtimeType.toString();

  void initHandlers(EntityHandlers<S> handlers);

  void initMigrations(EntityStateMigrations migrations);
}

abstract class EntityContext {
  /// Id of an actor that handles current command
  EntityId get entityId;

  /// Id of an actor or a flow that sent current command
  EntityId get senderId;

  DateTime get clock;

  // Logger get logger;

  Future<QueryResult> query(EntityId entityId, QueryDef query);

  void stop();
}

typedef EntityStateInitProjector<E extends RemoteEvent> = EntityState Function(
  E event,
);

abstract class EntityState {
  void project(RemoteEvent event);

  Map<String, dynamic> toJson();
}

abstract class EntityStateMigrations {
  void add(EntityStateMigration migration);

  Map<String, dynamic> migrate(int fromVersion, Map<String, dynamic> fromState);

  int get latestVersion;
}

abstract class EntityStateMigration {
  Map<String, dynamic> migrate(Map<String, dynamic> from);

  int get version;
}

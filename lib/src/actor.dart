import 'package:horda_core/horda_core.dart';
import 'package:logging/logging.dart';

typedef InitActorHandler<C extends RemoteCommand, E extends RemoteEvent>
    = Future<E> Function(
  C command,
  InitialActorContext context,
);

typedef ActorHandler<C extends RemoteCommand, E extends RemoteEvent,
        S extends ActorState<E>>
    = Future<E> Function(
  C command,
  ActorContext<E, S> context,
);

abstract class ActorHandlers<C extends RemoteCommand, E extends RemoteEvent,
    S extends ActorState<E>> {
  void addInit<CMD extends C>(InitActorHandler<CMD, E> handler);
  void add<CMD extends C>(ActorHandler<CMD, E, S> handler);
}

/// Actor is a worker that process commands in FIFO order.
abstract class Actor<C extends RemoteCommand, E extends RemoteEvent,
    S extends ActorState<E>> {
  void initHandlers(ActorHandlers<C, E, S> handlers);
}

abstract class InitialActorContext {
  /// Id of an actor that handles current command
  ActorId get actorId;

  /// Id of an actor or a flow that sent current command
  ActorId get senderId;

  DateTime get clock;

  Logger get logger;
}

abstract class ActorContext<E extends RemoteEvent, S extends ActorState<E>>
    extends InitialActorContext {
  S get state;

  void publish(E event);

  /// runs query on actor id, throws on errors
  Future<QueryResult> query(ActorId actorId, QueryDef query);
}

abstract class StatelessActor<C extends RemoteCommand, E extends RemoteEvent>
    implements Actor<C, E, NoActorState<E>> {}

typedef StatelessActorContext<E extends RemoteEvent>
    = ActorContext<E, NoActorState<E>>;

abstract class ActorState<E extends RemoteEvent> {
  void project(E event);
}

class NoActorState<E extends RemoteEvent> implements ActorState<E> {
  @override
  void project(E event) {
    // noop
  }
}

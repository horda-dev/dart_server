import 'package:horda_core/horda_core.dart';
import 'package:logging/logging.dart';

import 'actor.dart';

typedef FlowId = String;

typedef NewFlowFunc<E extends RemoteEvent> = FlowId? Function(E event);

typedef FlowHandler<E extends RemoteEvent> = Future<FlowResult> Function(
  E event,
  FlowContext context,
);

abstract class FlowHandlers {
  void add<E extends RemoteEvent>(FlowHandler<E> handler);
}

abstract class Flow {
  String get name => '$runtimeType';

  void initHandlers(FlowHandlers handlers);
}

abstract class FlowContext {
  FlowId get flowId;

  ActorId get senderId;

  DateTime get clock;

  Logger get logger;

  void send<C extends RemoteCommand, E extends RemoteEvent,
      S extends ActorState<E>>(
    ActorId actor,
    RemoteCommand cmd, [
    Actor<C, E, S> actorInstance,
  ]);

  Future<RemoteEvent> call<C extends RemoteCommand, E extends RemoteEvent,
      S extends ActorState<E>>(
    ActorId actor,
    RemoteCommand cmd, [
    Actor<C, E, S> actorInstance,
  ]);

  void subscribe(ActorId workerId);

  void unsubscribe(ActorId workerId);

  /// returns id that can be used for unschedule
  Future<String> schedule(ActorId to, Duration after, RemoteCommand cmd);

  Future<void> unschedule(String scheduleId);

  void stop();
}

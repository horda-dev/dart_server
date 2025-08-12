import 'package:horda_core/horda_core.dart';

typedef FlowHandler2<E extends RemoteEvent> = Future<FlowResult2> Function(
  E event,
  FlowContext2 context,
);

abstract class FlowHandlers2 {
  void add<E extends RemoteEvent>(
    FlowHandler2<E> handler,
    FromJsonFun<E> fromJson,
  );
}

abstract class Flow2 {
  void initHandlers(FlowHandlers2 handlers);
}

abstract class FlowContext2 {
  String get flowId;

  String get senderId;

  //
  // Actor
  //

  Future<E> callActor<E extends RemoteEvent>({
    required String name,
    required ActorId id,
    required RemoteCommand cmd,
    required FromJsonFun<E> fac,
  });

  Future<RemoteEvent> callActorDynamic({
    required String name,
    required ActorId id,
    required RemoteCommand cmd,
    required List<FromJsonFun<RemoteEvent>> fac,
  });

  void sendActor({
    required String name,
    required ActorId id,
    required RemoteCommand cmd,
  });

  /// returns id that can be used for unschedule
  Future<String> scheduleActor({
    required String name,
    required ActorId id,
    required Duration after,
    required RemoteCommand cmd,
  });

  void unscheduleActor({
    required String name,
    required String scheduleId,
  });

  //
  // Service
  //

  Future<E> callService<E extends RemoteEvent>({
    required String name,
    required RemoteCommand cmd,
    required FromJsonFun<E> fac,
  });

  @Deprecated('Services return only one event type.')
  Future<RemoteEvent> callServiceDynamic({
    required String name,
    required RemoteCommand cmd,
    required List<FromJsonFun<RemoteEvent>> fac,
  });

  void sendService({
    required String name,
    required RemoteCommand cmd,
  });

  /// returns id that can be used for unschedule
  Future<String> scheduleService({
    required String name,
    required Duration after,
    required RemoteCommand cmd,
  });

  void unscheduleService({
    required String name,
    required String scheduleId,
  });
}

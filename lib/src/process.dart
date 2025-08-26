import 'package:horda_core/horda_core.dart';

typedef ProcessHandler<E extends RemoteEvent> =
    Future<FlowResult> Function(E event, ProcessContext context);

abstract class ProcessHandlers {
  void add<E extends RemoteEvent>(
    ProcessHandler<E> handler,
    FromJsonFun<E> fromJson,
  );
}

abstract class Process {
  void initHandlers(ProcessHandlers handlers);
}

abstract class ProcessContext {
  String get processId;

  String get senderId;

  //
  // Entity
  //

  Future<E> callEntity<E extends RemoteEvent>({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
    required FromJsonFun<E> fac,
  });

  Future<RemoteEvent> callEntityDynamic({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
    required List<FromJsonFun<RemoteEvent>> fac,
  });

  void sendEntity({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
  });

  /// returns id that can be used for unschedule
  Future<String> scheduleEntity({
    required String name,
    required EntityId id,
    required Duration after,
    required RemoteCommand cmd,
  });

  void unscheduleEntity({required String name, required String scheduleId});

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

  void sendService({required String name, required RemoteCommand cmd});

  /// returns id that can be used for unschedule
  Future<String> scheduleService({
    required String name,
    required Duration after,
    required RemoteCommand cmd,
  });

  void unscheduleService({required String name, required String scheduleId});
}

import 'package:horda_core/horda_core.dart';

typedef ServiceHandler<C extends RemoteCommand> = Future<RemoteEvent> Function(
  C command,
  ServiceContext context,
);

abstract class ServiceHandlers {
  void add<C extends RemoteCommand>(
    ServiceHandler<C> handler,
    FromJsonFun<C> fromJson,
  );
}

/// Service is a worker that processes commands in parallel,
/// opposite to an actor that process commands is FIFO order.
abstract class Service {
  String get name => runtimeType.toString();

  void initHandlers(ServiceHandlers handlers);
}

abstract class ServiceContext {
  /// Id of an actor or a flow that sent current command
  ActorId get senderId;

  DateTime get clock;
}

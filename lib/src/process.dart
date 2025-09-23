import 'package:horda_core/horda_core.dart';

/// Handler function for processing business process events.
///
/// Receives an event that triggers a business process and coordinates
/// multiple entities and services to fulfill the client-initiated request.
typedef ProcessHandler<E extends RemoteEvent> =
    Future<FlowResult> Function(E event, ProcessContext context);

/// Registry for business process event handlers.
///
/// Manages the registration of handlers that respond to events
/// and orchestrate business processes across entities and services.
abstract class ProcessHandlers {
  /// Registers an event handler for a specific event type.
  ///
  /// [handler] - Function that processes the event and coordinates the business process
  /// [fromJson] - Deserializer for the event type
  void add<E extends RemoteEvent>(
    ProcessHandler<E> handler,
    FromJsonFun<E> fromJson,
  );
}

/// Business process that orchestrates entities and services to fulfill client requests.
///
/// A business process coordinates multiple components by:
/// - Sending commands to entities and services
/// - Receiving events as results of command handling
/// - Making decisions based on event types and payloads
/// - Completing when all required work is done
abstract class Process {
  /// Registers event handlers for this business process.
  ///
  /// Called during process setup to configure which events
  /// trigger this process and how they are handled.
  void initHandlers(ProcessHandlers handlers);
}

/// Context provided to business process handlers during event processing.
///
/// Contains runtime information and utilities needed to coordinate
/// entities and services within a business process.
abstract class ProcessContext {
  /// Unique identifier for the current process instance.
  String get processId;

  /// Identifier of the entity or user that sent the triggering event.
  String? get senderId;

  //
  // Entity Communication
  //

  /// Sends a command to an entity and waits for the resulting event.
  ///
  /// [name] - Entity type name (e.g., 'UserEntity', 'OrderEntity')
  /// [id] - Specific entity instance identifier
  /// [cmd] - Command to send to the entity
  /// [fac] - Factory function to deserialize the expected event type
  /// Returns the event produced by the entity
  Future<E> callEntity<E extends RemoteEvent>({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
    required FromJsonFun<E> fac,
  });

  /// Sends a command to an entity and waits for one of multiple possible event types.
  ///
  /// [name] - Entity type name
  /// [id] - Specific entity instance identifier
  /// [cmd] - Command to send to the entity
  /// [fac] - List of factory functions for possible event types
  /// Returns the event produced by the entity
  Future<RemoteEvent> callEntityDynamic({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
    required List<FromJsonFun<RemoteEvent>> fac,
  });

  /// Sends a fire-and-forget command to an entity without waiting for response.
  ///
  /// [name] - Entity type name
  /// [id] - Specific entity instance identifier
  /// [cmd] - Command to send to the entity
  void sendEntity({
    required String name,
    required EntityId id,
    required RemoteCommand cmd,
  });

  /// Schedules a command to be sent to an entity after a delay.
  ///
  /// [name] - Entity type name
  /// [id] - Specific entity instance identifier
  /// [after] - Delay before sending the command
  /// [cmd] - Command to send to the entity
  /// Returns schedule ID that can be used to cancel the scheduled command
  Future<String> scheduleEntity({
    required String name,
    required EntityId id,
    required Duration after,
    required RemoteCommand cmd,
  });

  /// Cancels a previously scheduled entity command.
  ///
  /// [name] - Entity type name
  /// [scheduleId] - ID returned from scheduleEntity
  void unscheduleEntity({required String name, required String scheduleId});

  //
  // Service Communication
  //

  /// Sends a command to a service and waits for the resulting event.
  ///
  /// [name] - Service type name (e.g., 'NotificationService', 'PaymentService')
  /// [cmd] - Command to send to the service
  /// [fac] - Factory function to deserialize the expected event type
  /// Returns the event produced by the service
  Future<E> callService<E extends RemoteEvent>({
    required String name,
    required RemoteCommand cmd,
    required FromJsonFun<E> fac,
  });

  /// Sends a command to a service and waits for one of multiple possible event types.
  ///
  /// [name] - Service type name
  /// [cmd] - Command to send to the service
  /// [fac] - List of factory functions for possible event types
  /// Returns the event produced by the service
  Future<RemoteEvent> callServiceDynamic({
    required String name,
    required RemoteCommand cmd,
    required List<FromJsonFun<RemoteEvent>> fac,
  });

  /// Sends a fire-and-forget command to a service without waiting for response.
  ///
  /// [name] - Service type name
  /// [cmd] - Command to send to the service
  void sendService({required String name, required RemoteCommand cmd});

  /// Schedules a command to be sent to a service after a delay.
  ///
  /// [name] - Service type name
  /// [after] - Delay before sending the command
  /// [cmd] - Command to send to the service
  /// Returns schedule ID that can be used to cancel the scheduled command
  Future<String> scheduleService({
    required String name,
    required Duration after,
    required RemoteCommand cmd,
  });

  /// Cancels a previously scheduled service command.
  ///
  /// [name] - Service type name
  /// [scheduleId] - ID returned from scheduleService
  void unscheduleService({required String name, required String scheduleId});
}

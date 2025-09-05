import 'package:horda_core/horda_core.dart';

/// Handler function for service commands.
///
/// Processes auxiliary tasks that are not part of the core business domain.
/// Services handle commands in any order and produce events as results.
typedef ServiceHandler<C extends RemoteCommand> =
    Future<RemoteEvent> Function(C command, ServiceContext context);

/// Registry for service command handlers.
///
/// Manages the registration of command handlers that process
/// auxiliary tasks triggered by business processes.
abstract class ServiceHandlers {
  /// Registers a command handler for a specific command type.
  ///
  /// [handler] - Function that processes the command and produces an event
  /// [fromJson] - Deserializer for the command type
  void add<C extends RemoteCommand>(
    ServiceHandler<C> handler,
    FromJsonFun<C> fromJson,
  );
}

/// Stateless component that performs auxiliary tasks to support business processes.
///
/// Services handle tasks that are not part of the core business domain.
/// Unlike entities, services process commands in parallel (no ordering) and
/// maintain no persistent state. Examples include ImageResizing, Moderation, Notifications.
abstract class Service {
  /// Returns the service type name used for identification.
  String get name => runtimeType.toString();

  /// Registers command handlers for this service.
  ///
  /// Called during service setup to configure which commands
  /// this service can process and how they are handled.
  void initHandlers(ServiceHandlers handlers);
}

/// Context provided to service command handlers during command processing.
///
/// Contains runtime information and utilities needed by service handlers
/// to process auxiliary tasks and interact with the system.
abstract class ServiceContext {
  /// Id of the entity or business process that sent the current command
  EntityId get senderId;

  /// Current system time for timestamping events
  DateTime get clock;
}

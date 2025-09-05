import 'package:horda_core/horda_core.dart';

/// Handler function for entity initialization commands.
///
/// Receives an init command and produces an init event to start the entity lifecycle.
/// This is a stateless function that creates the initial state of an entity.
typedef EntityInitHandler<C extends RemoteCommand, E extends RemoteEvent> =
    Future<E> Function(C command, EntityContext context);

/// Handler function for entity commands after initialization.
///
/// Receives a command and the current entity state, then produces an event.
/// Command handlers only read state fields and never mutate them directly.
typedef EntityHandler<S extends EntityState, C extends RemoteCommand> =
    Future<RemoteEvent> Function(C command, S state, EntityContext context);

/// Registry for entity command handlers and state management.
///
/// Manages the registration of init handlers, regular command handlers,
/// and state serialization functions for an entity.
abstract class EntityHandlers<S extends EntityState> {
  /// Registers an initialization command handler that creates the entity's initial state.
  ///
  /// [handler] - Function that processes the init command and produces init event
  /// [cmdFromJson] - Deserializer for the init command
  /// [stateInit] - Function that creates initial state from the init event
  void addInit<C extends RemoteCommand, E extends RemoteEvent>(
    EntityInitHandler<C, E> handler,
    FromJsonFun<C> cmdFromJson,
    EntityStateInitProjector<E> stateInit,
  );

  /// Registers a command handler for processing commands after entity initialization.
  ///
  /// [handler] - Function that processes commands using current state
  /// [fromJson] - Deserializer for the command type
  void add<C extends RemoteCommand>(
    EntityHandler<S, C> handler,
    FromJsonFun<C> fromJson,
  );

  /// Registers the state deserializer for this entity.
  ///
  /// [fromJson] - Function to deserialize state from JSON
  void addStateFromJson(FromJsonFun<S> fromJson);
}

/// Stateful component that represents a business domain entity.
///
/// Entities handle commands in strict FIFO order, maintaining persistent state
/// and producing events as results. Examples include BlogPost, Order, User.
///
/// Entity lifecycle begins when an EntityInitCommand is handled, producing
/// an EntityInitEvent that creates the initial EntityState.
abstract class Entity<S extends EntityState> {
  /// Returns the entity type name used for identification.
  String get name => runtimeType.toString();

  /// Registers command handlers and state management functions.
  ///
  /// Called during entity setup to configure how commands are processed
  /// and how state is managed.
  void initHandlers(EntityHandlers<S> handlers);

  /// Registers state migration functions for handling version changes.
  ///
  /// Used to upgrade entity state when the entity structure changes
  /// between application versions.
  void initMigrations(EntityStateMigrations migrations);
}

/// Context provided to entity command handlers during command processing.
///
/// Contains runtime information and utilities needed by command handlers
/// to process commands and interact with the system.
abstract class EntityContext {
  /// Id of the entity that handles the current command
  EntityId get entityId;

  /// Id of the entity or project that sent the current command
  EntityId get senderId;

  /// Current system time for timestamping events
  DateTime get clock;

  // Logger get logger;

  /// Queries another entity's state or views.
  ///
  /// [entityId] - Target entity to query
  /// [query] - Query definition specifying what data to retrieve
  Future<QueryResult> query(EntityId entityId, QueryDef query);

  /// Stops the entity, preventing it from processing further commands.
  void stop();
}

/// Function that creates initial entity state from an init event.
///
/// Called when an entity is first created to establish its initial state
/// from the data contained in the initialization event.
typedef EntityStateInitProjector<E extends RemoteEvent> =
    EntityState Function(E event);

/// Private state of an entity, read by command handlers and updated by events.
///
/// Entity state consists of fields used by command handlers to make decisions.
/// State is never visible to other entities or services. Events are projected
/// to state through projector functions that mutate state fields.
abstract class EntityState {
  /// Projects an event to update the entity's state fields.
  ///
  /// Called when events are produced to mutate state based on event payload.
  /// Each event type may have a projector that updates specific state fields.
  void project(RemoteEvent event);

  /// Serializes the current state to JSON for persistence.
  Map<String, dynamic> toJson();
}

/// Manages entity state migrations across application versions.
///
/// Handles upgrading entity state when the entity structure changes,
/// ensuring backward compatibility with previously persisted states.
abstract class EntityStateMigrations {
  /// Registers a migration for upgrading from a specific version.
  ///
  /// [migration] - Migration logic for upgrading state structure
  void add(EntityStateMigration migration);

  /// Migrates state from an older version to the latest version.
  ///
  /// [fromVersion] - Source version of the state
  /// [fromState] - State data in the old format
  /// Returns the migrated state in the latest format
  Map<String, dynamic> migrate(int fromVersion, Map<String, dynamic> fromState);

  /// The most recent version number of the entity state schema.
  int get latestVersion;
}

/// Single migration step for upgrading entity state structure.
///
/// Represents one version upgrade step in the entity state evolution,
/// containing the logic to transform state from one version to the next.
abstract class EntityStateMigration {
  /// Transforms state data from the previous version to this version.
  ///
  /// [from] - State data in the previous version format
  /// Returns the upgraded state data
  Map<String, dynamic> migrate(Map<String, dynamic> from);

  /// The target version number that this migration upgrades to.
  int get version;
}

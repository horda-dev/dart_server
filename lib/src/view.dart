import 'package:horda_core/horda_core.dart';

import 'entity.dart';

/// Function that initializes an EntityViewGroup from an entity init event.
/// 
/// Called when an entity is first created to establish its view group
/// from the data contained in the initialization event.
typedef EntityViewGroupInit<E extends RemoteEvent> =
    EntityViewGroup Function(E event);

/// Function that projects events to update entity views.
/// 
/// Called when events are produced to update view data based on event payload.
/// Projectors modify view state to reflect changes in the entity.
typedef EntityViewGroupProjector<E extends RemoteEvent> =
    void Function(E event);

/// Registry for entity view group projectors.
/// 
/// Manages the registration of projector functions that update
/// entity views in response to events.
abstract class EntityViewGroupProjectors {
  /// Registers an initialization projector for creating view groups from init events.
  /// 
  /// [projector] - Function that creates view group from init event
  void addInit<E extends RemoteEvent>(EntityViewGroupInit<E> projector);
  
  /// Registers an event projector for updating existing views.
  /// 
  /// [projector] - Function that updates views based on event data
  void add<E extends RemoteEvent>(EntityViewGroupProjector<E> projector);
}

/// Collection of views that represent queryable data derived from an entity.
/// 
/// EntityViewGroup provides read-optimized representations of entity data
/// that can be queried by business processes or external clients.
abstract class EntityViewGroup {
  /// Registers all views that belong to this entity.
  /// 
  /// [views] - View group registry to add views to
  void initViews(ViewGroup views);
  
  /// Registers projectors that update views when events occur.
  /// 
  /// [projectors] - Projector registry to add event handlers to
  void initProjectors(EntityViewGroupProjectors projectors);
}

/// Empty view group implementation for entities that don't expose queryable views.
/// 
/// Used when an entity doesn't need to provide any read-optimized data views
/// to external components.
class NoViewGroup<E extends RemoteEvent> implements EntityViewGroup {
  @override
  void initViews(ViewGroup group) {
    // noop
  }

  @override
  void initProjectors(EntityViewGroupProjectors projectors) {
    // noop
  }
}

/// Queryable data view derived from entity state.
/// 
/// Provides read-optimized access to specific aspects of entity data
/// that can be queried by business processes or external clients.
abstract class View {
  /// Entity identifier set by the view host when added to a view group
  EntityId? entityId;

  /// Default/initial value for this view
  dynamic get defaultValue;

  /// Unique name identifying this view within the entity
  String get name;

  /// Returns initial view data when the entity is first created
  Iterable<InitViewData> initValues();

  /// Returns pending changes to be applied to this view
  Iterable<Change> changes();
}

/// Registry for entity views.
/// 
/// Manages the collection of views that provide queryable data
/// representations of an entity's state.
abstract class ViewGroup {
  /// Adds a view to this entity's view group.
  /// 
  /// [view] - View instance to register
  void add(View view);
}

/// Initial data for a view when an entity is first created.
/// 
/// Contains the metadata and initial value needed to establish
/// a queryable view for an entity.
class InitViewData {
  /// Creates initial view data.
  /// 
  /// [key] - Entity identifier this view belongs to
  /// [name] - View name within the entity
  /// [value] - Initial value for the view
  /// [type] - Data type of the view value
  InitViewData({
    required this.key,
    required this.name,
    required this.value,
    required this.type,
  });

  /// Entity identifier this view belongs to
  final String key;

  /// View name within the entity
  final String name;

  /// Initial value for the view
  final dynamic value;

  /// Data type of the view value
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'value': _valueToJson(value),
      'type': type,
    };
  }

  static dynamic _valueToJson(dynamic value) {
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return value;
  }
}

/// View that holds a single typed value that can be queried and updated.
/// 
/// Provides a simple queryable representation of a single data field
/// from the entity's state.
class ValueView<T> extends View {
  /// Creates a value view with an initial value.
  /// 
  /// [name] - Unique name for this view
  /// [value] - Initial value
  ValueView({required this.name, required T value}) : _initValue = value;

  @override
  final String name;

  set value(T newValue) {
    _change = ValueViewChanged<T>(newValue);
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(entityId != null, 'view group host must set entityId');

    return [
      InitViewData(
        key: entityId!,
        name: name,
        value: _initValue,
        type: T.toString(),
      ),
    ];
  }

  @override
  Iterable<Change> changes() {
    if (_change == null) {
      return [];
    }

    // we do it here as change() called only once
    // for the change projection, opposite to setValue
    // that might be called multiple times
    final change = _change;
    _change = null;
    return [change!];
  }

  final T _initValue;
  Change? _change;

  @override
  T get defaultValue => _initValue;
}

/// View that maintains an integer counter that can be incremented, decremented, or reset.
/// 
/// Provides a queryable counter representation useful for tracking quantities,
/// counts, or numeric metrics derived from entity events.
class CounterView extends View {
  /// Creates a counter view with an initial value.
  /// 
  /// [name] - Unique name for this view
  /// [value] - Initial counter value (defaults to 0)
  CounterView({required this.name, int value = 0}) : _initValue = value;

  @override
  final String name;

  void increment(int by) {
    _changes.add(CounterViewIncremented(by: by));
  }

  void decrement(int by) {
    _changes.add(CounterViewDecremented(by: by));
  }

  void reset(int newValue) {
    _changes.add(CounterViewReset(newValue: newValue));
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(entityId != null, 'view group host must set entityId');

    return [
      InitViewData(key: entityId!, name: name, value: _initValue, type: 'int'),
    ];
  }

  @override
  Iterable<Change> changes() {
    if (_changes.isEmpty) {
      return [];
    }

    // we do it here as change() called only once
    // for the change projection, opposite to setValue
    // that might be called multiple times
    final changes = [..._changes];
    _changes.clear();
    return changes;
  }

  final int _initValue;
  final _changes = <Change>[];

  @override
  int get defaultValue => _initValue;
}

/// View that holds a reference to another entity with optional attributes.
/// 
/// Provides a queryable representation of relationships between entities,
/// allowing access to referenced entity data and attributes.
class RefView<E extends Entity> extends View {
  /// Creates a reference view with an initial entity reference.
  /// 
  /// [name] - Unique name for this view
  /// [value] - Initial entity reference (can be null)
  RefView({required this.name, required EntityId? value}) : _initValue = value;

  @override
  final String name;

  set value(EntityId? newValue) {
    _change = RefViewChanged(newValue);
  }

  /// returns ref value attribute with the given name for modification
  ValueRefAttribute<T> valueAttr<T>(EntityId attrId, String attrName) {
    assert(entityId != null, 'view group host must set entityId');

    return ValueRefAttribute(attrId, attrName, _attrChanges);
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(entityId != null, 'view group host must set entityId');

    return [
      InitViewData(
        key: entityId!,
        name: name,
        value: _initValue,
        type: 'String?',
      ),
    ];
  }

  @override
  Iterable<Change> changes() {
    final changes = <Change>[];

    // we do it here as change() called only once
    // for the change projection, opposite to setValue
    // that might be called multiple times
    if (_change != null) {
      changes.add(_change!);
      _change = null;
    }

    for (final change in _attrChanges.values) {
      changes.add(change);
    }
    _attrChanges.clear();

    return changes;
  }

  final String? _initValue;
  RefViewChanged? _change;

  // TODO: change to list
  final _attrChanges = <RefIdNamePair, RefValueAttributeChanged>{};

  @override
  String? get defaultValue => _initValue;
}

/// View that maintains a list of entity references with attributes.
/// 
/// Provides a queryable collection of entity relationships, supporting
/// list operations and per-item attributes for complex data structures.
class RefListView<E extends Entity> extends View {
  /// Creates a reference list view with initial entity references.
  /// 
  /// [name] - Unique name for this view
  /// [value] - Initial list of entity references (defaults to empty)
  RefListView({required this.name, Iterable<EntityId>? value})
    : _initValue = value ?? <EntityId>[];

  @override
  final String name;

  void addItem(EntityId itemId) {
    _changes.add(ListViewItemAdded(itemId));
  }

  void addItemIfAbsent(EntityId itemId) {
    _changes.add(ListViewItemAddedIfAbsent(itemId));
  }

  void removeItem(EntityId itemId) {
    _changes.add(ListViewItemRemoved(itemId));
  }

  void changeItem(EntityId oldItemId, EntityId newItemId) {
    _changes.add(
      ListViewItemChanged(oldItemId: oldItemId, newItemId: newItemId),
    );
  }

  void moveItem(EntityId itemId, int newIndex) {
    _changes.add(ListViewItemMoved(itemId, newIndex));
  }

  void clear() {
    _changes.add(ListViewCleared());
  }

  /// returns counter attribute with the given name for modification
  /// if attribute with the given name doesn't exist, it will be created
  /// by the first event, assuming initial value is zero
  CounterAttribute counterAttr(EntityId itemId, String attrName) {
    assert(entityId != null, 'view group host must set entityId');

    return CounterAttribute(itemId, attrName, _attrChanges);
  }

  /// returns value attribute with the given name for modification
  /// if attribute with the given name doesn't exist, it will be created
  /// by the first event, assuming initial value is zero
  ValueRefAttribute<T> valueAttr<T>(EntityId itemId, String attrName) {
    assert(entityId != null, 'view group host must set entityId');

    return ValueRefAttribute(itemId, attrName, _attrChanges);
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(entityId != null, 'view group host must set entityId');

    return [
      InitViewData(
        key: entityId!,
        name: name,
        value: _initValue,
        type: 'List<String>',
      ),
    ];
  }

  @override
  Iterable<Change> changes() {
    final changes = <Change>[];

    // we do it here as change() called only once
    // for the change projection, opposite to setValue
    // that might be called multiple times
    if (_changes.isNotEmpty) {
      changes.addAll(_changes);
      _changes.clear();
    }

    for (final change in _attrChanges.values) {
      changes.add(change);
    }
    _attrChanges.clear();

    return changes;
  }

  final Iterable<String> _initValue;
  final _changes = <Change>[];
  // TODO: change to list
  final _attrChanges = <RefIdNamePair, Change>{};

  @override
  Iterable<String> get defaultValue => _initValue;
}

/// Counter attribute attached to items in reference views.
/// 
/// Provides increment, decrement, and reset operations for numeric
/// attributes associated with referenced entities.
class CounterAttribute {
  /// Creates a counter attribute for a specific item and attribute name.
  /// 
  /// [attrId] - Identifier of the item this attribute belongs to
  /// [attrName] - Name of the attribute
  /// [_changes] - Change tracking map
  CounterAttribute(EntityId attrId, EntityId attrName, this._changes)
    : _key = (itemId: attrId, name: attrName);

  void increment(int by) {
    _changes[_key] = CounterAttrIncremented(
      attrId: _key.itemId,
      attrName: _key.name,
      by: by,
    );
  }

  void decrement(int by) {
    _changes[_key] = CounterAttrDecremented(
      attrId: _key.itemId,
      attrName: _key.name,
      by: by,
    );
  }

  void reset(int newValue) {
    _changes[_key] = CounterAttrReset(
      attrId: _key.itemId,
      attrName: _key.name,
      newValue: newValue,
    );
  }

  final RefIdNamePair _key;
  final Map<RefIdNamePair, Change> _changes;
}

/// Typed value attribute attached to items in reference views.
/// 
/// Provides typed value storage and modification for attributes
/// associated with referenced entities.
class ValueRefAttribute<T> {
  /// Creates a value attribute for a specific item and attribute name.
  /// 
  /// [attrId] - Identifier of the item this attribute belongs to
  /// [attrName] - Name of the attribute
  /// [_changes] - Change tracking map
  ValueRefAttribute(EntityId attrId, String attrName, this._changes)
    : _key = (itemId: attrId, name: attrName);

  set value(T newValue) {
    _changes[_key] = RefValueAttributeChanged(
      attrId: _key.itemId,
      attrName: _key.name,
      newValue: newValue,
    );
  }

  final RefIdNamePair _key;
  // id is a list itemId when used by ListView2
  // id is an empty string when used by RefView2
  final Map<RefIdNamePair, Change> _changes;
}

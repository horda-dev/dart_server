import 'package:horda_core/horda_core.dart';

import 'entity.dart';

typedef EntityViewGroupInit<E extends RemoteEvent> = EntityViewGroup Function(
  E event,
);

typedef EntityViewGroupProjector<E extends RemoteEvent> = void Function(
    E event);

abstract class EntityViewGroupProjectors {
  void addInit<E extends RemoteEvent>(EntityViewGroupInit<E> projector);
  void add<E extends RemoteEvent>(EntityViewGroupProjector<E> projector);
}

abstract class EntityViewGroup {
  void initViews(ViewGroup views);
  void initProjectors(EntityViewGroupProjectors projectors);
}

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

abstract class View {
  // this is set by view host once
  // view has added to the view group
  EntityId? entityId;

  dynamic get defaultValue;

  String get name;

  Iterable<InitViewData> initValues();

  Iterable<Change> changes();
}

abstract class ViewGroup {
  void add(View view);
}

class InitViewData {
  InitViewData({
    required this.key,
    required this.name,
    required this.value,
    required this.type,
  });

  final String key;

  final String name;

  final dynamic value;

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

class ValueView<T> extends View {
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
    return [
      change!,
    ];
  }

  final T _initValue;
  Change? _change;

  @override
  T get defaultValue => _initValue;
}

class CounterView extends View {
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
      InitViewData(
        key: entityId!,
        name: name,
        value: _initValue,
        type: 'int',
      ),
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
    final changes = [
      ..._changes,
    ];
    _changes.clear();
    return changes;
  }

  final int _initValue;
  final _changes = <Change>[];

  @override
  int get defaultValue => _initValue;
}

class RefView<E extends Entity> extends View {
  RefView({required this.name, required EntityId? value}) : _initValue = value;

  @override
  final String name;

  set value(EntityId? newValue) {
    _change = RefViewChanged(newValue);
  }

  /// returns ref value attribute with the given name for modification
  ValueRefAttribute<T> valueAttr<T>(EntityId attrId, String attrName) {
    assert(entityId != null, 'view group host must set entityId');

    return ValueRefAttribute(
      attrId,
      attrName,
      _attrChanges,
    );
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

class RefListView<E extends Entity> extends View {
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
      ListViewItemChanged(
        oldItemId: oldItemId,
        newItemId: newItemId,
      ),
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

    return CounterAttribute(
      itemId,
      attrName,
      _attrChanges,
    );
  }

  /// returns value attribute with the given name for modification
  /// if attribute with the given name doesn't exist, it will be created
  /// by the first event, assuming initial value is zero
  ValueRefAttribute<T> valueAttr<T>(EntityId itemId, String attrName) {
    assert(entityId != null, 'view group host must set entityId');

    return ValueRefAttribute(
      itemId,
      attrName,
      _attrChanges,
    );
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

class CounterAttribute {
  CounterAttribute(
    EntityId attrId,
    EntityId attrName,
    this._changes,
  ) : _key = (itemId: attrId, name: attrName);

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

class ValueRefAttribute<T> {
  ValueRefAttribute(
    EntityId attrId,
    String attrName,
    this._changes,
  ) : _key = (itemId: attrId, name: attrName);

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

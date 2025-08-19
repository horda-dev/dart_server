import 'package:horda_core/horda_core.dart';

import 'actor2.dart';

typedef ActorViewGroupInit<E extends RemoteEvent> = ActorViewGroup2 Function(
  E event,
);

typedef ActorViewGroupProjector<E extends RemoteEvent> = void Function(E event);

abstract class ActorViewGroupProjectors {
  void addInit<E extends RemoteEvent>(ActorViewGroupInit<E> projector);
  void add<E extends RemoteEvent>(ActorViewGroupProjector<E> projector);
}

abstract class ActorViewGroup2 {
  void initViews(ViewGroup2 views);
  void initProjectors(ActorViewGroupProjectors projectors);
}

class NoViewGroup2<E extends RemoteEvent> implements ActorViewGroup2 {
  @override
  void initViews(ViewGroup2 group) {
    // noop
  }

  @override
  void initProjectors(ActorViewGroupProjectors projectors) {
    // noop
  }
}

abstract class View2 {
  // this is set by view host once
  // view has added to the view group
  ActorId? actorId;

  dynamic get defaultValue;

  String get name;

  Iterable<InitViewData> initValues();

  Iterable<Change> changes();
}

abstract class ViewGroup2 {
  void add(View2 view);
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

class ValueView2<T> extends View2 {
  ValueView2({required this.name, required T value}) : _initValue = value;

  @override
  final String name;

  set value(T newValue) {
    _change = ValueViewChanged<T>(newValue);
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(actorId != null, 'view group host must set actorId');

    return [
      InitViewData(
        key: actorId!,
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

class CounterView2 extends View2 {
  CounterView2({required this.name, int value = 0}) : _initValue = value;

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
    assert(actorId != null, 'view group host must set actorId');

    return [
      InitViewData(
        key: actorId!,
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

class RefView2<E extends Actor2> extends View2 {
  RefView2({required this.name, required ActorId? value}) : _initValue = value;

  @override
  final String name;

  set value(ActorId? newValue) {
    _change = RefViewChanged(newValue);
  }

  /// returns ref value attribute with the given name for modification
  ValueRefAttribute2<T> valueAttr<T>(ActorId attrId, String attrName) {
    assert(actorId != null, 'view group host must set actorId');

    return ValueRefAttribute2(
      attrId,
      attrName,
      _attrChanges,
    );
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(actorId != null, 'view group host must set actorId');

    return [
      InitViewData(
        key: actorId!,
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
  final _attrChanges = <RefIdNamePair, RefValueAttributeChanged2>{};

  @override
  String? get defaultValue => _initValue;
}

class RefListView2<E extends Actor2> extends View2 {
  RefListView2({required this.name, Iterable<ActorId>? value})
      : _initValue = value ?? <ActorId>[];

  @override
  final String name;

  void addItem(ActorId itemId) {
    _changes.add(ListViewItemAdded(itemId));
  }

  void addItemIfAbsent(ActorId itemId) {
    _changes.add(ListViewItemAddedIfAbsent(itemId));
  }

  void removeItem(ActorId itemId) {
    _changes.add(ListViewItemRemoved(itemId));
  }

  void changeItem(ActorId oldItemId, ActorId newItemId) {
    _changes.add(
      ListViewItemChanged(
        oldItemId: oldItemId,
        newItemId: newItemId,
      ),
    );
  }

  void moveItem(ActorId itemId, int newIndex) {
    _changes.add(ListViewItemMoved(itemId, newIndex));
  }

  void clear() {
    _changes.add(ListViewCleared());
  }

  /// returns counter attribute with the given name for modification
  /// if attribute with the given name doesn't exist, it will be created
  /// by the first event, assuming initial value is zero
  CounterAttribute2 counterAttr(ActorId itemId, String attrName) {
    assert(actorId != null, 'view group host must set actorId');

    return CounterAttribute2(
      itemId,
      attrName,
      _attrChanges,
    );
  }

  /// returns value attribute with the given name for modification
  /// if attribute with the given name doesn't exist, it will be created
  /// by the first event, assuming initial value is zero
  ValueRefAttribute2<T> valueAttr<T>(ActorId itemId, String attrName) {
    assert(actorId != null, 'view group host must set actorId');

    return ValueRefAttribute2(
      itemId,
      attrName,
      _attrChanges,
    );
  }

  @override
  Iterable<InitViewData> initValues() {
    assert(actorId != null, 'view group host must set actorId');

    return [
      InitViewData(
        key: actorId!,
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

class CounterAttribute2 {
  CounterAttribute2(
    ActorId attrId,
    ActorId attrName,
    this._changes,
  ) : _key = (itemId: attrId, name: attrName);

  void increment(int by) {
    _changes[_key] = CounterAttrIncremented2(
      attrId: _key.itemId,
      attrName: _key.name,
      by: by,
    );
  }

  void decrement(int by) {
    _changes[_key] = CounterAttrDecremented2(
      attrId: _key.itemId,
      attrName: _key.name,
      by: by,
    );
  }

  void reset(int newValue) {
    _changes[_key] = CounterAttrReset2(
      attrId: _key.itemId,
      attrName: _key.name,
      newValue: newValue,
    );
  }

  final RefIdNamePair _key;
  final Map<RefIdNamePair, Change> _changes;
}

class ValueRefAttribute2<T> {
  ValueRefAttribute2(
    ActorId attrId,
    String attrName,
    this._changes,
  ) : _key = (itemId: attrId, name: attrName);

  set value(T newValue) {
    _changes[_key] = RefValueAttributeChanged2(
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

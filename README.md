# Horda Server

[![Pub Package](https://img.shields.io/pub/v/horda_server.svg)](https://pub.dev/packages/horda_server)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/horda_server)](https://pub.dev/packages/horda_server)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

*Stateful serverless backend for ambitions Flutter applications.*

## What is Horda Server?

Horda Server is a Dart framework for building stateful serverless backends specifically designed for Flutter applications. It's part of the [Horda platform](https://horda.ai) - the first stateful serverless platform that allows you to create and deploy complex, fully persistent, real-time backends.

Unlike traditional backends that force you to think in database tables, Horda Server enables you to **think in business concepts**. It eliminates databases, transactions, and concurrency handling while providing real-time, strongly typed Dart APIs that integrate seamlessly with Flutter apps.

## Key Features

- **Message Driven Architecture**: Model stateful business domains with entities that handle commands and produce events
- **Business Process Orchestration**: Coordinate complex workflows across multiple entities and services
- **Stateful Entities**: Stateful business domain objects like `User`, `Order`, or `BlogPost`
- **Stateless Services**: Auxiliary task processing for operations like notifications, payments, and image processing
- **Real-time Views**: Query-optimized data projections with live updates to Flutter apps
- **Flutter Integration**: Strongly typed Dart query API with real-time synchronization

## Core Concepts

### Business Processes

Business processes orchestrate entities and services to fulfill client-initiated requests. They:

- Coordinate multiple components through command/event interactions
- Make decisions based on event types and payloads
- Handle complex workflows that span multiple entities and services
- Complete when all required work is done

### Entities

Entities are stateful business domain objects that represent core concepts in your application like `User`, `Order`, or `BlogPost`. They:

- Handle commands in strict FIFO order
- Maintain private state that's never directly visible to other components
- Produce events as results of successful command processing
- Project events to update their internal state

### Services

Services are stateless components that perform auxiliary tasks supporting business processes. They:

- Process commands in parallel (no ordering constraints)
- Handle tasks outside the core business domain
- Support business processes with operations like image resizing, content moderation, and notifications

### Views

Views provide public representations of entity data that can be accessed by Flutter apps. They:

- Offer real-time updates when underlying entity produces an event
- Support various types: single values, counters, entity references, and lists
- Enable efficient querying without exposing private entity state

## Quick Start

### Entity Example

```dart
class CounterEntity extends Entity<CounterState> {
  Future<RemoteEvent> increment(
    IncrementCounter command,
    CounterState state,
    EntityContext context,
  ) async {
    if (state.isFrozen) {
      throw CounterEntityException('counter is frozen');
    }

    return CounterIncremented(amount: command.amount);
  }

  Future<RemoteEvent> freeze(
    FreezeCounter command,
    CounterState state,
    EntityContext context,
  ) async {
    if (state.isFrozen) {
      throw CounterEntityException('counter is already frozen');
    }

    return CounterFreezeChanged(newValue: true);
  }

  // ...
}

@JsonSerializable()
class CounterState extends EntityState {
  bool get isFrozen => _isFrozen;

  CounterState({bool isFrozen = false}) : _isFrozen = isFrozen;

  void freezeChanged(CounterFreezeChanged event) {
    _isFrozen = event.newValue;
  }

  bool _isFrozen;

  // ...
}

```

### Entity View Example

```dart
class CounterViewGroup extends EntityViewGroup {
  final ValueView<String> nameView;
  final CounterView valueView;
  final ValueView<String> freezeStatusView;

  CounterViewGroup.fromInitEvent(CounterCreated event)
    : nameView = ValueView(name: 'name', value: event.name),
      valueView = CounterView(name: 'value', value: event.count),
      freezeStatusView = ValueView(name: 'freezeStatus', value: "not frozen");

  void incremented(CounterIncremented event) {
    valueView.increment(event.amount);
  }

  void decremented(CounterDecremented event) {
    valueView.decrement(event.amount);
  }

  void freezeChanged(CounterFreezeChanged event) {
    if (event.newValue) {
      freezeStatusView.value = "frozen";
    } else {
      freezeStatusView.value = "not frozen";
    }
  }

  // ...
}
```

### Service Example

```dart
class ValidationService extends Service {
  Future<RemoteEvent> validate(
    ValidateCounterName command,
    ServiceContext context,
  ) async {
    if (command.name.length > 10) {
      return CounterNameValidated.invalid(invalidReason: 'too long');
    }

    return CounterNameValidated.valid();
  }

  // ...
}
```

### Business Process Example

```dart
Future<FlowResult> create(
  CreateCounterRequested event,
  ProcessContext context,
) async {
  // generate counter id
  final newCounterId = Xid().toString();

  // validate counter name
  final validationResult = await context.callService<CounterNameValidated>(
    name: 'ValidationService',
    cmd: ValidateCounterName(name: event.name),
    fac: CounterNameValidated.fromJson,
  );

  // if name is invalid finish the process with an error
  if (!validationResult.isValid) {
    return FlowResult.error('counter name is invalid');
  }

  // create counter entity
  await context.callEntity<CounterCreated>(
    name: 'CounterEntity',
    id: newCounterId,
    cmd: CreateCounter(name: event.name, initialValue: event.initialValue),
    fac: CounterCreated.fromJson,
  );

  // add the counter to the list
  await context.callEntity<CounterAddedToList>(
    name: 'CounterListEntity',
    id: kCounterListEntityId,
    cmd: AddCounterToList(counterId: newCounterId),
    fac: CounterAddedToList.fromJson,
  );

  return FlowResult.ok(newCounterId);
}
```

### Command/Event Example

**Commands** represent requests for work and follow the `VerbNoun` format in present tense:
- `CreateUser`, `UpdateProfile`, `ProcessPayment`
- Include all necessary data for task completion
- Use simple types that can be JSON serialized

**Events** represent completed work and follow the `NounVerb` format in past tense:
- `UserCreated`, `ProfileUpdated`, `PaymentProcessed`
- Produced only on successful command handling
- Contain complete outcome information

```dart
// Command example
@JsonSerializable()
class IncrementCounter extends RemoteCommand {
  final int amount;

  IncrementCounter({this.amount = 1});
}

// Event example  
@JsonSerializable()
class CounterIncremented extends RemoteEvent {
  final int newValue;

  CounterIncremented({required this.newValue});
}

```

## Links

- [Horda Client](https://horda.ai) - Horda client for Flutter apps
- [Pub Packages](https://pub.dev/publishers/horda.dev/packages) - Horda packages on pub.dev
- [GitHub Repository](https://github.com/horda-ai) - Horda repositories
- [Horda Platform](https://github.com/horda-ai/dart_client) - Horda platform website

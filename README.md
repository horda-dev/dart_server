# Horda Server

[![Pub Package](https://img.shields.io/pub/v/horda_server.svg)](https://pub.dev/packages/horda_server)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/horda_server)](https://pub.dev/packages/horda_server)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

*Stateful serverless backend framework for Flutter applications*

## What is Horda Server?

Horda Server is a Dart framework for building stateful serverless backends specifically designed for Flutter applications. It's part of the [Horda platform](https://horda.ai) - the first stateful serverless platform that goes beyond Firebase by offering sophisticated backend management tailored for the Flutter ecosystem.

Unlike traditional backends that force you to think in database tables, Horda Server enables you to **think in business concepts**. It eliminates manual database management, transactions, and concurrency handling while providing real-time, strongly typed Dart APIs that integrate seamlessly with Flutter apps.

**Key Differentiators:**
- Entity-command-event architecture for complex business logic
- Real-time data synchronization with Flutter apps
- Strongly typed Dart query APIs
- Built-in support for both web and mobile Flutter applications

## Key Features

- **Entity-Command-Event Architecture**: Model stateful business domains with entities that handle commands and produce events
- **Business Process Orchestration**: Coordinate complex workflows across multiple entities and services
- **Real-time Views**: Query-optimized data projections with live updates to Flutter apps
- **Stateless Services**: Auxiliary task processing for operations like notifications, payments, and image processing
- **Flutter Integration**: Strongly typed Dart query API with real-time synchronization

## Core Concepts

### Entities

Entities are stateful business domain objects that represent core concepts in your application like `User`, `Order`, or `BlogPost`. They:

- Handle commands in strict FIFO order
- Maintain private state that's never directly visible to other components
- Produce events as results of successful command processing
- Project events to update their internal state

### Business Processes

Business processes orchestrate entities and services to fulfill client-initiated requests. They:

- Coordinate multiple components through command/event interactions
- Make decisions based on event types and payloads
- Handle complex workflows that span multiple entities and services
- Complete when all required work is done

### Services

Services are stateless components that perform auxiliary tasks supporting business processes. They:

- Process commands in parallel (no ordering constraints)
- Handle tasks outside the core business domain
- Support business processes with operations like image resizing, content moderation, and notifications

### Views

Views provide query-optimized representations of entity data that can be accessed by Flutter apps. They:

- Offer real-time updates when underlying entity state changes
- Support various types: single values, counters, entity references, and lists
- Enable efficient querying without exposing private entity state

## Installation

Add Horda Server to your `pubspec.yaml`:

```yaml
dependencies:
  horda_server: ^0.12.0
```

## Quick Start

### Basic Entity Example

```dart
import 'package:horda_server/horda_server.dart';

// Entity implementation
class CounterEntity extends Entity<CounterState> {
  Future<CounterCreated> _createCounter(
    CreateCounter cmd,
    EntityContext context,
  ) async {
    return CounterCreated(
      counterId: context.entityId,
      initialValue: cmd.initialValue,
    );
  }
  
  Future<RemoteEvent> _incrementCounter(
    IncrementCounter cmd,
    CounterState state,
    EntityContext context,
  ) async {
    return CounterIncremented(
      counterId: context.entityId,
      newValue: state.value + cmd.amount,
    );
  }

  @override
  void initHandlers(EntityHandlers<CounterState> handlers) {
    // boilerplate code
  }
}

// Entity state
class CounterState extends EntityState {
  CounterState({required this.value});
  
  final int value;
  
  @override
  void project(RemoteEvent event) {
    // boilerplate code
  }
  
  @override
  Map<String, dynamic> toJson() => {'value': value};
}
```

### Basic Business Process Example

```dart
// Order processing workflow
class ProcessOrderFlow extends Process {
  @override
  void initHandlers(ProcessHandlers handlers) {
    handlers.add<OrderSubmitted>(
      _processOrder,
      OrderSubmitted.fromJson,
    );
  }
  
  Future<FlowResult> _processOrder(
    OrderSubmitted event,
    ProcessContext context,
  ) async {
    // Step 1: Validate payment
    final paymentResult = await context.callService<PaymentProcessed>(
      name: 'PaymentService',
      cmd: ProcessPayment(
        orderId: event.orderId,
        amount: event.amount,
      ),
      fac: PaymentProcessed.fromJson,
    );
    
    if (!paymentResult.success) {
      return FlowResult.error('Payment failed: ${paymentResult.reason}');
    }
    
    // Step 2: Create order entity
    final orderCreated = await context.callEntity<OrderCreated>(
      name: 'OrderEntity',
      id: EntityId(event.orderId),
      cmd: CreateOrder(
        customerId: event.customerId,
        items: event.items,
        totalAmount: event.amount,
      ),
      fac: OrderCreated.fromJson,
    );
    
    // Step 3: Update customer's order history
    await context.sendEntity(
      name: 'CustomerEntity',
      id: EntityId(event.customerId),
      cmd: AddOrderToHistory(orderId: orderCreated.orderId),
    );
    
    return FlowResult.ok();
  }
}
```

### Basic Service Example

```dart
// Email notification service
class EmailService extends Service {
  @override
  void initHandlers(ServiceHandlers handlers) {
    handlers.add<SendEmail>(
      _sendEmail,
      SendEmail.fromJson,
    );
  }
  
  Future<RemoteEvent> _sendEmail(
    SendEmail cmd,
    ServiceContext context,
  ) async {
    // Simulate email sending logic
    final success = await _deliverEmail(
      to: cmd.recipient,
      subject: cmd.subject,
      body: cmd.body,
    );
    
    return EmailSent(
      emailId: _generateEmailId(),
      recipient: cmd.recipient,
      sentAt: context.clock,
      delivered: success,
    );
  }
  
  Future<bool> _deliverEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    // Email delivery implementation
    return true;
  }
  
  String _generateEmailId() => DateTime.now().millisecondsSinceEpoch.toString();
}
```

## API Reference

### Entity APIs

- **`Entity<S>`** - Base class for all entities with state type `S`
- **`EntityHandlers<S>`** - Registry for command handlers and state management
- **`EntityContext`** - Runtime context providing entity ID, sender ID, clock, and query capabilities
- **`EntityState`** - Base class for entity state with event projection and JSON serialization

### Process APIs

- **`Process`** - Base class for business process orchestration
- **`ProcessHandlers`** - Registry for event handlers that trigger business processes
- **`ProcessContext`** - Communication utilities for coordinating entities and services

### Service APIs

- **`Service`** - Base class for stateless auxiliary task processing
- **`ServiceHandlers`** - Registry for service command handlers
- **`ServiceContext`** - Runtime context for service command execution

### View APIs

- **`EntityViewGroup`** - Collection of queryable views derived from entity data
- **`View`** - Base interface for all view types
- **`ValueView<T>`** - Single typed value view
- **`CounterView`** - Integer counter with increment/decrement operations
- **`RefView<E>`** - Reference to another entity with attributes
- **`RefListView<E>`** - List of entity references with per-item attributes

## Architecture Patterns

### Command/Event Design

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
class CreateBlogPost extends RemoteCommand {
  CreateBlogPost({
    required this.title,
    required this.content,
    required this.authorId,
  });
  
  final String title;
  final String content;
  final String authorId;
}

// Event example  
class BlogPostCreated extends RemoteEvent {
  BlogPostCreated({
    required this.postId,
    required this.title,
    required this.authorId,
    required this.createdAt,
  });
  
  final String postId;
  final String title;
  final String authorId;
  final DateTime createdAt;
}
```

### State Management

Entity state is private and never directly visible to other components. State changes happen through event projections:

```dart
class BlogPostState extends EntityState {
  BlogPostState({
    required this.title,
    required this.content,
    required this.authorId,
    required this.isPublished,
  });
  
  final String title;
  final String content;  
  final String authorId;
  final bool isPublished;
  
  @override
  void project(RemoteEvent event) {
    switch (event.runtimeType) {
      case BlogPostCreated:
        // Initialize state from creation event
        break;
      case BlogPostPublished:
        // Update published status
        break;
    }
  }
}
```

### Business Process Design

Business processes coordinate multiple components through event-driven orchestration:

```dart
Future<FlowResult> _publishBlogPost(
  PublishBlogPostRequested event,
  ProcessContext context,
) async {
  // Step 1: Moderate content
  final moderated = await context.callService<ContentModerated>(
    name: 'ModerationService',
    cmd: ModerateContent(content: event.content),
    fac: ContentModerated.fromJson,
  );
  
  if (!moderated.approved) {
    return FlowResult.error('Content rejected: ${moderated.reason}');
  }
  
  // Step 2: Publish the post
  final published = await context.callEntity<BlogPostPublished>(
    name: 'BlogPostEntity',
    id: EntityId(event.postId),
    cmd: PublishPost(),
    fac: BlogPostPublished.fromJson,
  );
  
  // Step 3: Notify subscribers
  await context.sendService(
    name: 'NotificationService',
    cmd: NotifySubscribers(
      authorId: published.authorId,
      postTitle: published.title,
    ),
  );
  
  return FlowResult.ok();
}
```

## Advanced Topics

### Entity State Migrations

Handle entity evolution with version management:

```dart
class BlogPostStateMigration implements EntityStateMigration {
  @override
  int get version => 2;
  
  @override
  Map<String, dynamic> migrate(Map<String, dynamic> from) {
    // Add new field in version 2
    return {
      ...from,
      'tags': <String>[], // New field with default value
    };
  }
}
```

### View Projections

Create queryable representations of entity data:

```dart
class BlogPostViewGroup extends EntityViewGroup {
  @override
  void initViews(ViewGroup views) {
    views.add(ValueView<String>(name: 'title', value: ''));
    views.add(ValueView<bool>(name: 'isPublished', value: false));
    views.add(CounterView(name: 'viewCount', value: 0));
  }
  
  @override
  void initProjectors(EntityViewGroupProjectors projectors) {
    projectors.add<BlogPostCreated>((event) {
      // Update views when post is created
    });
    
    projectors.add<BlogPostViewed>((event) {
      // Increment view counter
    });
  }
}
```

### Error Handling

Implement robust error handling patterns:

```dart
Future<FlowResult> _handleOrder(
  OrderSubmitted event,
  ProcessContext context,
) async {
  try {
    // Process order steps...
    return FlowResult.ok();
  } catch (e) {
    // Log error and return failure
    return FlowResult.error('Order processing failed: $e');
  }
}
```

## Flutter Integration

Horda Server provides strongly typed Dart APIs that integrate seamlessly with Flutter applications:

- **Real-time Data Sync**: Views automatically update Flutter UI when entity state changes
- **Type Safety**: Generated Dart classes ensure compile-time safety
- **Query API**: Efficient querying of entity views and data
- **Cross-platform**: Works with both mobile and web Flutter applications

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Links

- [Horda Platform](https://horda.ai) - Official Horda platform website
- [Pub Packages](https://pub.dev/publishers/horda.dev/packages) - Horda packages on pub.dev
- [GitHub Repository](https://github.com/horda-ai) - Horda repositories


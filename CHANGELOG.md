## 0.16.0

 - **FEAT**: add singleton entity support

## 0.15.0

 - **FEAT**: update horda_core to 0.15.0

## 0.14.0

 - **FEAT**: update horda_core to 0.14.0

## 0.13.0

 - **BREAKING CHANGE**: make ProcessContext.senderId nullable

## 0.12.1

 - **DOCS**: readme file
 - **DOCS**: add doc comments for all public types

## 0.12.0

 - **BREAKING CHANGE**: rename public API
 - **CI**: add publish Github workflow

## 0.11.1

 - **CI**: initial Github CI flow

## 0.11.0

 - **FEAT**: add a generic type to RefListView2 to specify referred entity name.

## 0.10.0

 - **FEAT**: add a generic type to RefView2 to specify referred entity name.
 - **BREAKING CHANGE**: rename ListView2 to RefListView2.

## 0.9.14

 - **FEAT**: service type.

## 0.9.13+4

 - **FIX**: fix ValueViewChanged fromJson.

## 0.9.13+3

 - Update a dependency to the latest release.

## 0.9.13+2

 - Update a dependency to the latest release.

## 0.9.13+1

 - **FIX**: you can get init change only once.

## 0.9.13

 - **FEAT**: sync actor start.

## 0.9.12+1

 - Update a dependency to the latest release.

## 0.9.12

 - **FEAT**: stop actor api.

## 0.9.11

 - **FEAT**: retrofit new actor state.

## 0.9.10

 - **FEAT**: retrofit new actor views.

## 0.9.9+4

 - Update a dependency to the latest release.

## 0.9.9+3

 - Update a dependency to the latest release.

## 0.9.9+2

 - Update a dependency to the latest release.

## 0.9.9+1

 - Update a dependency to the latest release.

## 0.9.9

 - **FEAT**: pulsar context sender id.

## 0.9.8

 - **FEAT**: fluir client v2.

## 0.9.7+1

 - Update a dependency to the latest release.

## 0.9.7

 - **FEAT**: change v2.

## 0.9.6

 - **FEAT**: add FlowContext2.callDynamic().

## 0.9.5

 - **FEAT**: pulsar flow context.

## 0.9.4

 - **FEAT**: pulsar actor context.

## 0.9.3

 - **FEAT**: pulsar flow host.

## 0.9.2+3

 - Update a dependency to the latest release.

## 0.9.2+2

 - Update a dependency to the latest release.

## 0.9.2+1

 - Update a dependency to the latest release.

## 0.9.2

 - **FEAT**: production of multiple view changes.

## 0.9.1+1

 - Update a dependency to the latest release.

## 0.9.1

 - **FEAT**: view cache.

# 0.9.0

- added ValueAttribute support to ListView
- updated fluir_core to 0.11.0

## 0.8.1

- reuploaded with 0.7.2 changes that were missing

## 0.8.0

- added ListView.addItemIfAbsent()
- updated fluir_core to 0.11.0

## 0.7.2

- track attribute versions

## 0.7.1

- updated fluir_core to 0.10.0

## 0.7.0

- added ActorContext.query() method

## 0.6.0

- Flow handlers now return FlowResult, rename FlowContext eventFrom to senderId
- added new API to RefView and ListView to work with attribute values
- changed View initChanges() and changes() to return multiple ChangeEnvelops

## 0.5.0

- Flow handlers now return FlowResult, rename FlowContext eventFrom to senderId
- updated fluir_core to 0.8.0

## 0.4.0

- refactored messages into remote and local messages
- updated fluir_core to 0.7.0

## 0.3.0

- start actor via start command
- refactor actor command handling

## 0.2.0

- refactored view Events into Changes
- removed unused actor, view and widget related FlowContext methods

## 0.1.0

- initial version
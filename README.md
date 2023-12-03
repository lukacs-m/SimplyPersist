# SimplyPersist

`SimplyPersist` is a Swift package that provides a convenient and efficient way to perform persistence operations using SwiftData.
It allows operation on background threads by implementing the new `ModelActor` protocol.

## Features

- Define and manage your data models easily.
- Save, fetch, and delete data objects asynchronously.
- Configurable batch saving for improved performance.
- Error handling with a custom `PersistenceError` enum.

## Installation

To integrate `SimplyPersist` into your Xcode project using Swift Package Manager, follow these steps:

1. Open your project in Xcode.
2. Select `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the following repository URL: `https://github.com/lukacs-m/SimplyPersist`
4. Follow the prompts to complete the integration.

## Usage

### Initialization

```swift
import SimplyPersist

// Initialize PersistenceService with models and optional configuration
let persistenceService = try PersistenceService(for: YourModel.self, migrationPlan: YourMigrationPlan.self, configurations: YourConfigurations.self)
```

### Saving

```swift
let model = YourPersistableData()
try await persistenceService.save(data: model)
```

### Fetching

```swift
// Fetch data with optional predicate and sorting descriptor
let fetchedData = try await persistenceService.fetch(predicate: yourPredicate, sortingDescriptor: yourSortingDescriptor)

"or"

let fetchedData = try await persistenceService.fetch(identifier: ID)
```

### Delete

```swift
// Delete a single data object
persistenceService.delete(element: yourPersistableElement)

// Delete all data of specified types
try await persistenceService.deleteAll(dataTypes: [YourPersistableData.Type])
```

### Batch Saving

```swift
// Batch save an array of data with a specified batch size
try await persistenceService.batchSave(content: yourDataArray, batchSize: yourBatchSize)
```

### Error handling

`PersistenceService` provides a custom error type, `PersistenceError`, which includes:

- `noSchema`: Indicates that no schema is available.
Handle errors using Swift's do-catch mechanism:

```swift
do {
    // Your persistence operations here
} catch let error as PersistenceError {
    switch error {
    case .noSchema:
        print("Error: No schema available.")
    // Handle other cases as needed
    }
} catch {
    print("An unexpected error occurred: \(error)")
}
```

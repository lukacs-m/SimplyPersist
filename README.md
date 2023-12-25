# SimplyPersist

`SimplyPersist` is a Swift package that provides a convenient and efficient way to perform persistence operations using SwiftData.
It allows operation on background threads by implementing the new `ModelActor` protocol.

`SimplyPersist` is a Swift package designed to facilitate efficient and easy-to-use persistence operations in Swift applications. 
It utilizes Swift's concurrency model, including the `ModelActor` protocol, to allow safe operations on background threads. 
This package is built on top of Swift new data persistence capabilities, providing a streamlined API for managing your data models and performing database operations asynchronously.



## Features

- **Data Model Management**: Define and manage your data models with ease. SimplyPersist allows for clear structuring of persistent models, ensuring that they conform to the Persistable protocol for consistency and reliability.
- **Asynchronous Operations**: Perform save, fetch, and delete operations asynchronously, leveraging Swift's modern concurrency features for responsive and efficient data handling.
- **Batch Saving**: Optimize performance with configurable batch saving options, allowing for efficient handling of large sets of data.
- **Custom Error Handling**: Utilize the `PersistenceError` enum for handling specific persistence-related errors, such as `noSchema`, ensuring robust error management in your persistence layer.

## Installation

To integrate `SimplyPersist` into your Xcode project using Swift Package Manager, follow these steps:

1. Open your project in Xcode.
2. Select `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the following repository URL: `https://github.com/lukacs-m/SimplyPersist`
4. Follow the prompts to complete the integration.

## Requirements

- Xcode 13.0 or later
- Swift 5.9 or later

## Usage

### Initialization

To start using `SimplyPersist`, initialize the `PersistenceService with your data models and optional configurations.

```swift
import SimplyPersist

// Initialize PersistenceService with models and optional configuration
let persistenceService = try PersistenceService(for: YourModel.self, migrationPlan: YourMigrationPlan.self, configurations: YourConfigurations.self)
```

### Saving

Save your data objects asynchronously using the save method.

```swift
let model = YourPersistableData()
try await persistenceService.save(data: model)
```

### Fetching

Fetch data objects asynchronously using predicates for filtering and sorting descriptors for ordering.

```swift
// Fetch data with optional predicate and sorting descriptor
let fetchedData = try await persistenceService.fetch(predicate: yourPredicate, sortingDescriptor: yourSortingDescriptor)

"or"
// Fetch a data object by identifier
let fetchedData = try await persistenceService.fetch(identifier: ID)
```

### Delete

Delete data objects asynchronously either individually or in bulk.

```swift
// Delete a single data object
persistenceService.delete(element: yourPersistableElement)

// Delete all data of specified types
try await persistenceService.deleteAll(dataTypes: [YourPersistableData.Type])
```

### Batch Saving

For improved performance, especially with large data sets, use batch saving.


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

## Advanced Features

`SimplyPersist is designed to be flexible and adaptable to various use cases, including more complex data handling and migration scenarios.

## Contributing

Contributions to `SimplyPersist are welcome! 

## Support

For support, questions, or to report issues, please open an issue on the GitHub repository: https://github.com/lukacs-m/SimplyPersist/issues.

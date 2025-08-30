# SimplyPersist

[![Swift Version](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+%20|%20macOS%2012.0+%20|%20watchOS%208.0+%20|%20tvOS%2015.0+-lightgrey.svg)](https://developer.apple.com/swift/)
[![SwiftData](https://img.shields.io/badge/SwiftData-Compatible-blue.svg)](https://developer.apple.com/xcode/swiftdata/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A powerful, actor-based Swift package that simplifies SwiftData persistence operations with async/await support. SimplyPersist provides a clean, type-safe API for managing your SwiftData models with built-in batch processing, transaction handling, and memory-efficient operations.

## Features

- 🎯 **Actor-based concurrency** - Thread-safe operations with Swift's actor model
- 🚀 **Async/await support** - Modern Swift concurrency patterns
- 📦 **Batch processing** - Memory-efficient handling of large datasets
- 🔄 **Transaction management** - Safe data mutations with automatic rollback
- 🎛️ **Flexible initialization** - Multiple init methods for different use cases
- 🔍 **Advanced querying** - Predicate-based filtering and custom fetch descriptors
- 📊 **Performance optimized** - Lazy loading and batch fetching for large datasets
- ✅ **Type-safe** - Leverages Swift's type system for compile-time safety

## Requirements

- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add PersistenceService to your project using Xcode:

1. Go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/lukacs-m/SimplyPersist`
3. Choose your version requirements

Or add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/lukacs-m/SimplyPersist", from: "1.0.0")
]
```

## Quick Start

### 1. Define Your Models

First, create your SwiftData models conforming to the `Persistable` protocol:

```swift
import SwiftData
import SimplyPersist

@Model
class User: Persistable {
    var id: UUID
    var name: String
    var email: String
    var createdAt: Date
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
}

@Model  
class Post: Persistable {
    var id: UUID
    var title: String
    var content: String
    var author: User?
    var publishedAt: Date
    
    init(title: String, content: String, author: User? = nil) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.author = author
        self.publishedAt = Date()
    }
}
```

### 2. Initialize PersistenceService

```swift
import SimplyPersist

class DataManager {
    let persistenceService: any PersistenceServicing
    
    init() async throws {
        // Initialize with multiple models
        self.persistenceService = try PersistenceService(for: User.self, Post.self)
    }
}
```

### 3. Basic Operations

```swift
// Create and save a user
let user = User(name: "John Doe", email: "john@example.com")
try await persistenceService.save(user)

// Fetch all users
let users: [User] = try await persistenceService.fetchAll()

// Fetch users with predicate
let activeUsers = try await persistenceService.fetch(
    predicate: #Predicate<User> { $0.name.contains("John") }
)

// Delete a user
try persistenceService.delete(user)
```

## Detailed Usage

### Initialization Options

PersistenceService offers multiple initialization methods:

```swift
// 1. With variadic models (recommended for simple cases)
let service1 = try PersistenceService(for: User.self, Post.self, autosave: true)

// 2. With schema and migration plan
let schema = Schema([User.self, Post.self])
let service2 = try PersistenceService(
    for: schema,
    migrationPlan: MyMigrationPlan.self,
    autosave: false
)

// 3. With custom configuration
let config = ModelConfiguration(schema: schema, url: customURL)
let service3 = try PersistenceService(with: config)
```

### Saving Data

#### Single Model
```swift
let user = User(name: "Alice Smith", email: "alice@example.com")
try await persistenceService.save(user)
```

#### Multiple Models
```swift
let users = [
    User(name: "Bob Johnson", email: "bob@example.com"),
    User(name: "Carol White", email: "carol@example.com")
]
try await persistenceService.save(users)
```

#### Batch Saving (for large datasets)
```swift
let largeUserList = generateUsers(count: 10000)
try await persistenceService.saveByBatch(largeUserList, batchSize: 500)
```

### Fetching Data

#### Basic Fetching
```swift
// Fetch all
let allUsers: [User] = try await persistenceService.fetchAll()

// Fetch with predicate
let recentUsers = try await persistenceService.fetch(
    predicate: #Predicate<User> { 
        $0.createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }
)

// Fetch with sorting
let sortedUsers = try await persistenceService.fetch(
    sortingDescriptor: [SortDescriptor(\User.name, order: .forward)]
)
```

#### Advanced Fetching
```swift
// Fetch first matching
let firstUser = try await persistenceService.fetchFirst(
    predicate: #Predicate<User> { $0.email == "john@example.com" }
)

// Fetch by identifier
if let user: User? = await persistenceService.fetch(byIdentifier: userID) {
    print("Found user: \(user.name)")
}

// Custom fetch descriptor
var descriptor = FetchDescriptor<Post>(
    predicate: #Predicate { $0.publishedAt > Date().addingTimeInterval(-86400) }
)
descriptor.fetchLimit = 10
descriptor.includePendingChanges = false

let recentPosts = try await persistenceService.fetch(using: descriptor)
```

#### Batch Fetching (memory efficient for large datasets)
```swift
let batchResults = try await persistenceService.fetchByBatch(
    using: FetchDescriptor<User>(),
    batchSize: 100
)

// Process in batches
for batch in batchResults {
    // Process each batch
    print("Processing batch of \(batch.count) users")
}
```

### Updating Data

Use transactions for safe updates:

```swift
try await persistenceService.performTransaction {
    user.name = "Updated Name"
    user.email = "newemail@example.com"
}
```

### Deleting Data

#### Single Model
```swift
try persistenceService.delete(user)
```

#### Multiple Models
```swift
let usersToDelete = [user1, user2, user3]
try persistenceService.delete(usersToDelete)
```

#### Conditional Deletion
```swift
try await persistenceService.delete(
    User.self,
    matching: #Predicate { $0.createdAt < oldDate }
)
```

#### Delete All of Type
```swift
try persistenceService.deleteAll(ofTypes: [User.self, Post.self])
```

### Utility Operations

#### Count Models
```swift
let userCount = try await persistenceService.count(User.self)
let activeUserCount = try await persistenceService.count(
    User.self,
    predicate: #Predicate { $0.isActive }
)
```

#### Enumerate and Transform
```swift
let userNames = try await persistenceService.enumerate(
    using: FetchDescriptor<User>()
) { user in
    user.name.uppercased()
}
```

#### Manual Commits
```swift
// Disable autosave
await persistenceService.setAutosave(false)

// Make changes...
try await persistenceService.save(user)

// Manually commit when ready
try await persistenceService.commitChanges()
```

## Error Handling

PersistenceService uses Swift's error handling system. Common patterns:

```swift
do {
    let users = try await persistenceService.fetchAll<User>()
    // Handle success
} catch let error as PersistenceError {
    // Handle persistence-specific errors
    switch error {
    case .noSchema:
        print("Schema not found")
    }
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

## Best Practices

### 1. Use Batch Operations for Large Datasets
```swift
// Instead of this:
for user in largeUserArray {
    try await persistenceService.save(user)
}

// Do this:
try await persistenceService.saveByBatch(largeUserArray, batchSize: 1000)
```

### 2. Leverage Predicates for Efficient Queries
```swift
// Efficient predicate-based fetching
let activeUsers = try await persistenceService.fetch(
    predicate: #Predicate<User> { $0.isActive && $0.lastLoginDate > cutoffDate }
)
```

### 3. Use Transactions for Complex Updates
```swift
try await persistenceService.performTransaction {
    // Multiple related updates
    user.updateProfile(with: newData)
    user.posts.forEach { $0.markAsUpdated() }
}
```

### 4. Consider Memory Usage with Large Datasets
```swift
// For processing large datasets, use batch fetching
let batchResults = try await persistenceService.fetchByBatch(
    using: descriptor,
    batchSize: 500
)
```

## Migration Support

PersistenceService supports SwiftData migration plans:

```swift
enum MyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self
    ]
    
    static var stages: [MigrationStage] = [
        MigrationStage.custom(
            fromVersion: SchemaV1.self,
            toVersion: SchemaV2.self,
            willMigrate: { context in
                // Migration logic
            }
        )
    ]
}

let service = try PersistenceService(
    for: schema,
    migrationPlan: MyMigrationPlan.self
)
```

## Performance Considerations

- Use batch operations for large datasets (1000+ items)
- Leverage predicates to filter data at the database level
- Consider disabling autosave for bulk operations
- Use batch fetching for memory-efficient processing
- Implement proper indexing on frequently queried properties

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

If you have questions or need help:

- 🐛 Report bugs via [GitHub Issues](https://github.com/lukacs-m/SimplyPersist/issues)
- 💬 Start a [Discussion](https://github.com/lukacs-m/SimplyPersist/discussions)

## Acknowledgments

- Built on top of Apple's SwiftData framework
- Inspired by modern Swift concurrency patterns
- Thanks to the Swift community for feedback and contributions

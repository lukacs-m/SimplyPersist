// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftData

extension FetchResultsCollection: @unchecked @retroactive Sendable {}

/**
 `PersistenceService` is an actor-based Swift package that facilitates persistence operations for SwiftData models. It is designed to be flexible, allowing developers to easily manage data models and perform asynchronous save, fetch, and delete operations.
 */
public actor PersistenceService: PersistenceServicing, ModelActor {
    public let modelContainer: ModelContainer
    public let modelExecutor: any ModelExecutor
    private let context: ModelContext

    /// Designated initializer with schema
    /// - Parameters:
    ///   - schema: The schema describing your models
    ///   - migrationPlan: Optional migration plan
    ///   - configurations: Model configurations (default: empty)
    ///   - autosave: Whether autosave should be enabled (default: true)
    public init(for schema: Schema,
                migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
                configurations: [ModelConfiguration] = [],
                autosave: Bool = true) throws {
        modelContainer = try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: configurations
        )

        context = ModelContext(modelContainer)
        context.autosaveEnabled = autosave
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    // Convenience init: variadic models
    public init(
        for models: any PersistentModel.Type...,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        configurations: [ModelConfiguration] = [],
        autosave: Bool = false
    ) throws {
        let schema = Schema(models)
        try self.init(for: schema, migrationPlan: migrationPlan, configurations: configurations, autosave: autosave)
    }

    // Convenience init: single configuration
    public init(
        with configuration: ModelConfiguration,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        autosave: Bool = false
    ) throws {
        guard let schema = configuration.schema else {
            throw PersistenceError.noSchema
        }
        try self.init(for: schema, migrationPlan: migrationPlan, configurations: [configuration], autosave: autosave)
    }

    /// Enable or disable autosave on the context
    public func setAutosave(_ enabled: Bool) async {
        context.autosaveEnabled = enabled
    }
}

// MARK: - Data saving functions
public extension PersistenceService {

    ///   Save a data object asynchronously.
    /// - Parameter model: `model`: The model object conforming to the `Persistable` protocol.
    func save(_ model: some Persistable) async throws {
        context.insert(model)
        try commitToDb()
    }

    /// Saves multiple models in a single transaction and commits changes to storage.
    /// - Parameter models: Array of models conforming to the `Persistable` protocol.
    func save(_ models: [some Persistable]) async throws {
        try context.transaction {
            for model in models {
                context.insert(model)
            }
        }
        try commitToDb()
    }

    /// Saves multiple models in batches for better memory management.
    /// - Parameters:
    ///   - models: Array of models to save.
    ///   - batchSize: Number of models to process per batch.
    func saveByBatch(_ models: [some Persistable], batchSize: Int = 1000) async throws {
        let chunks = models.chunked(into: batchSize)
        for chunk in chunks {
            try context.transaction {
                for element in chunk {
                    context.insert(element)
                }
            }
        }
        try commitToDb()
    }
}

// MARK: - Data fetching functions
public extension PersistenceService {
    /// Fetches models based on predicate and sort descriptors.
    /// - Parameters:
    ///   - predicate: Optional predicate for filtering results.
    ///   - sortDescriptors: Array of sort descriptors for ordering results.
    /// - Returns: Array of models matching the criteria.
    func fetch<T: Persistable>(predicate: Predicate<T>? = nil,
                               sortingDescriptor: [SortDescriptor<T>] = []) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortingDescriptor)
        return try context.fetch(descriptor)
    }

    /// Fetches models using a custom fetch descriptor.
    /// - Parameter fetchDescriptor: The fetch configuration.
    /// - Returns: Array of models matching the descriptor criteria.
    func fetch<T: Persistable>(using fetchDescriptor: FetchDescriptor<T>) async throws -> [T] {
        return try context.fetch(fetchDescriptor)
    }

    /// Fetches models in batches for memory-efficient processing of large datasets.
    /// - Parameters:
    ///   - fetchDescriptor: The fetch configuration.
    ///   - batchSize: Number of objects to fetch per batch.
    /// - Returns: A lazy collection that fetches data in batches.
    func fetchByBatch<T: Persistable>(using fetchDescriptor: FetchDescriptor<T>,
                                      batchSize: Int) async throws -> FetchResultsCollection<T> {
        var updatedDescriptor = fetchDescriptor
        updatedDescriptor.includePendingChanges = false
        return try context.fetch(updatedDescriptor, batchSize: batchSize)
    }

    /// Fetches the first model matching the given predicate.
    /// - Parameter predicate: Predicate for filtering results.
    /// - Returns: The first matching model, or nil if none found.
    func fetchFirst<T: Persistable>(predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }


    /// Fetches a model by its persistent identifier.
    /// - Parameter identifier: The persistent identifier of the model.
    /// - Returns: The model if found, otherwise nil.
    func fetch<T: Persistable>(byIdentifier identifier: PersistentIdentifier) async -> T? {
        context.registeredModel(for: identifier) as T?
    }

    ///  Fetch all data objects of a specific type asynchronously.
    /// - Returns: An array of object of type `T`
    func fetchAll<T: Persistable>() async throws -> [T] {
        try await fetch()
    }
}

// MARK: - Data deletion functions
public extension PersistenceService {
    // Deletes a single model from the context.
    /// - Parameter model: The model to be deleted.
    func delete(_ model: some Persistable) throws {
        context.delete(model)
        try commitToDb()
    }

    /// Deletes models matching the given predicate.
    /// - Parameters:
    ///   - modelType: The type of models to delete.
    ///   - predicate: Optional predicate for filtering models to delete.
    ///   - includeSubclasses: Whether to include subclasses in deletion.
    func delete<T: Persistable>(_ modelType: T.Type,
                                matching predicate: Predicate<T>? = nil,
                                includeSubclasses: Bool = true) async throws {
        try context.delete(model: modelType, where: predicate, includeSubclasses: includeSubclasses)
        try commitToDb()
    }

    /// Deletes multiple models from the context.
    /// - Parameter models: Array of models to delete.
    func delete<T: Persistable>(_ models: [T]) throws {
        for model in models {
            context.delete(model)
        }
        try commitToDb()
    }

    /// Deletes all models of the specified types.
    /// - Parameter modelTypes: Array of model types to delete all instances of.
    func deleteAll(ofTypes modelTypes: [any Persistable.Type]) throws {
        for model in modelTypes {
            try context.delete(model: model.self)
        }
        try commitToDb()
    }
}

// MARK: - Data update & utils functions
public extension PersistenceService {
    /// Performs model mutations inside a SwiftData transaction.
    /// - Parameter operation: A closure to mutate models safely.
    /// Should be used to update models safely
    func performTransaction(_ operation: @escaping @Sendable () throws -> Void) async throws {
        try context.transaction {
            try operation()
        }
        try commitToDb()
    }

    /// Counts the number of models matching the given criteria.
    /// - Parameters:
    ///   - modelType: The type of model to count.
    ///   - predicate: Optional predicate for filtering.
    /// - Returns: The count of matching models.
    func count<T: Persistable>(_ modelType: T.Type,
                               predicate: Predicate<T>? = nil) async throws -> Int {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    /// Enumerates over models using a fetch descriptor and applies a transformation.
    /// - Parameters:
    ///   - fetchDescriptor: The fetch configuration.
    ///   - transform: Transformation to apply to each model.
    /// - Returns: Array of transformed results.
    func enumerate<T: Persistable, R: Sendable>(using descriptor: FetchDescriptor<T>, transform: @Sendable @escaping (T) throws -> R) async throws -> [R] {
        var resutls: [R] = []
        try context.enumerate(descriptor) { model in
            try resutls.append(transform(model))
        }
        return resutls
    }

    /// Commits any pending changes to persistent storage.
    func commitChanges() async throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

private extension PersistenceService {
    func commitToDb() throws {
        if !context.autosaveEnabled, context.hasChanges {
            try context.save()
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

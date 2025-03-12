// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftData

/**
 `PersistenceService` is an actor-based Swift package that facilitates persistence operations for SwiftData models. It is designed to be flexible, allowing developers to easily manage data models and perform asynchronous save, fetch, and delete operations.
*/
public actor PersistenceService: PersistenceServicing, ModelActor {
    public let modelContainer: ModelContainer
    public let modelExecutor: any ModelExecutor
    private let context: ModelContext

    ///  Initialize `PersistenceService` for a set of data models.
    /// - Parameters:
    ///   - models:  A variadic parameter for the data model types.
    ///   - migrationPlan: Optional schema migration plan.
    ///   - configurations: Configurations for the models.
    public init(for models: any PersistentModel.Type...,
                migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
                configurations: ModelConfiguration...) throws {
        let schema = Schema(models)
       try self.init(for: schema, migrationPlan: migrationPlan, configurations: configurations)
    }
    
    ///  Initialize `PersistenceService` for a given schema.
    /// - Parameters:
    ///   - schema:  The schema containing data models.
    ///   - migrationPlan: Optional schema migration plan.
    ///   - configurations: Configurations for the models.
    public init(for schema: Schema,
                migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
                configurations: ModelConfiguration...) throws {
        try self.init(for: schema, migrationPlan: migrationPlan, configurations: configurations)
    }
    
    ///  Initialize `PersistenceService` for a given schema with an array of configurations.
    /// - Parameters:
    ///   - schema: The schema containing data models.
    ///   - migrationPlan: Optional schema migration plan.
    ///   - configurations: Configurations for the models.
    public init(for schema: Schema,
                migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
                configurations: [ModelConfiguration] = []) throws {
        modelContainer = try ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: configurations)
        context = ModelContext(modelContainer)
        context.autosaveEnabled = true
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
    
    ///  Initialize `PersistenceService` with a single model configuration and an optional migration plan.
    /// - Parameters:
    ///   - configuration: The configuration for the model.
    ///   - migrationPlan: Optional schema migration plan.
    public init(with configuration: ModelConfiguration, and migrationPlan: (any SchemaMigrationPlan.Type)? = nil) throws {
        guard let schema = configuration.schema else {
            throw PersistenceError.noSchema
        }
        modelContainer = try ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: [configuration])
        context = ModelContext(modelContainer)
        context.autosaveEnabled = true
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }
}

public extension PersistenceService {
    
    ///   Save a data object asynchronously.
    /// - Parameter data: `data`: The data object conforming to the `Persistable` protocol.
    func save(data: some Persistable) async throws {
        context.insert(data)
        try context.save()
    }
    
    ///  Fetch data objects asynchronously based on a predicate and sorting descriptors.
    /// - Parameters:
    ///   - predicate: Optional predicate for filtering data.
    ///   - sortingDescriptor: Sorting descriptors for the fetched data.
    /// - Returns: An array of object of type `T`
    func fetch<T: Persistable>(predicate: Predicate<T>? = nil,
                               sortingDescriptor: [SortDescriptor<T>] = []) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortingDescriptor)
        return try context.fetch(descriptor)
    }
    
    /// Fetch a single data object asynchronously based on a predicate.
    /// - Parameter predicate: Predicate for filtering data.
    /// - Returns: An optionnal object  of type`T`
    func fetchOne<T: Persistable>(predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
    
    ///  Fetch a data object asynchronously based on its identifier.
    /// - Parameter identifier: The identifier of the data object.
    /// - Returns: An optionnal object  of type`T`
    func fetch<T: Persistable>(identifier: PersistentIdentifier) async -> T? {
        guard let result = context.registeredModel(for: identifier) as T? else {
            return nil
        }
        return result
    }
    
    ///  Fetch all data objects of a specific type asynchronously.
    /// - Returns: An array of object of type `T`
    func fetchAll<T: Persistable>() async throws -> [T] {
        try await fetch()
    }
    
    ///  Delete a single data object asynchronously.
    /// - Parameter element:  The data object to be deleted.
    func delete(element: some Persistable) throws {
        context.delete(element)
        try context.save()
    }
    
    func delete<T: Persistable>(_ modelType: T.Type, predicate: Predicate<T>) async throws {
        try context.delete(model: modelType.self, where: predicate)
    }

    ///  Delete all data objects of specified types asynchronously.
    /// - Parameter dataTypes: An array of data types to delete.
    func deleteAll(dataTypes: [any Persistable.Type]) throws {
        for model in dataTypes {
            try context.delete(model: model)
        }
    }

    ///  Batch save an array of data objects with a specified batch size asynchronously.
    /// - Parameters:
    ///   - content: An array of data objects to be saved.
    ///   - batchSize: The size of each batch for saving.
    func batchSave(content: [some Persistable], batchSize: Int = 1000) async throws {
        let chunks = content.chunked(into: batchSize)
        for chunk in chunks {
            for element in chunk {
                context.insert(element)
            }
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

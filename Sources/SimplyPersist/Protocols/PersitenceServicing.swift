//
//  PersitenceServicing.swift
//
//
//  Created by Martin Lukacs on 02/12/2023.
//

import Foundation
import SwiftData

/// A type alias representing a protocol conformed to by data models.
public typealias Persistable = Equatable & PersistentModel & Sendable

///  Protocol defining the contract for a persistence service.
public protocol PersistenceServicing: Sendable {
    func setAutosave(_ enabled: Bool) async
    
    func save(_ model: some Persistable) async throws
    func save(_ models: [some Persistable]) async throws
    func saveByBatch(_ models: [some Persistable], batchSize: Int) async throws

    func fetch<T: Persistable>(predicate: Predicate<T>?,
                               sortingDescriptor: [SortDescriptor<T>]) async throws -> [T]
    func fetch<T: Persistable>(using fetchDescriptor: FetchDescriptor<T>) async throws -> [T]
    func fetchByBatch<T: Persistable>(using fetchDescriptor: FetchDescriptor<T>,
                                      batchSize: Int) async throws -> FetchResultsCollection<T>
    func fetchFirst<T: Persistable>(predicate: Predicate<T>) async throws -> T?
    func fetch<T: Persistable>(byIdentifier: PersistentIdentifier) async -> T?
    func fetchAll<T: Persistable>() async throws -> [T]
    
    func delete(_ model: some Persistable) async throws
    func delete<T: Persistable>(_ modelType: T.Type, matching predicate: Predicate<T>?, includeSubclasses: Bool) async throws
    func delete<T: Persistable>(_ models: [T]) async throws
    func deleteAll(ofTypes dataTypes: [any Persistable.Type]) async throws
    
    func performTransaction(_ operation: @escaping @Sendable () throws -> Void) async throws
    func count<T: Persistable>(_ modelType: T.Type, predicate: Predicate<T>?) async throws -> Int
    func enumerate<T: Persistable, R: Sendable>(using descriptor: FetchDescriptor<T>,
                                                transform: @Sendable @escaping (T) throws -> R) async throws -> [R]
    func commitChanges() async throws
}

public extension PersistenceServicing {
    func fetch<T: Persistable>(predicate: Predicate<T>? = nil,
                               sortingDescriptor: [SortDescriptor<T>] = []) async throws -> [T] {
        try await fetch(predicate: predicate, sortingDescriptor: sortingDescriptor)
    }

    func saveByBatch(_ content: [some Persistable], batchSize: Int = 1000) async throws {
        try await saveByBatch(content, batchSize: batchSize)
    }
    
    func delete<T: Persistable>(_ modelType: T.Type, matching predicate: Predicate<T>? = nil, includeSubclasses: Bool = true) async throws {
        try await delete(modelType, matching: predicate, includeSubclasses: includeSubclasses)
    }

    func count<T: Persistable>(_ modelType: T.Type, predicate: Predicate<T>? = nil) async throws -> Int {
        try await count(modelType, predicate: predicate)
    }
}

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
    func save(data: some Persistable) async throws
    func fetch<T: Persistable>(predicate: Predicate<T>?,
                              sortingDescriptor: [SortDescriptor<T>]) async throws -> [T]
    func fetch<T: Persistable>(identifier: PersistentIdentifier) async -> T?
    func fetchOne<T: Persistable>(predicate: Predicate<T>) async throws -> T?
    func fetchAll<T: Persistable>() async throws -> [T]
    func delete(element: some Persistable) async throws
    func delete<T: Persistable>(_ modelType: T.Type, predicate: Predicate<T>) async throws
    func deleteAll(dataTypes: [any Persistable.Type]) async throws
    func batchSave(content: [some Persistable], batchSize: Int) async throws
}

public extension PersistenceServicing {
    func fetch<T: Persistable>(predicate: Predicate<T>? = nil,
                              sortingDescriptor: [SortDescriptor<T>] = []) async throws -> [T] {
        try await fetch(predicate: predicate, sortingDescriptor: sortingDescriptor)
    }

    func batchSave(content: [some Persistable], batchSize: Int = 1000) async throws {
        try await batchSave(content: content, batchSize: batchSize)
    }
}

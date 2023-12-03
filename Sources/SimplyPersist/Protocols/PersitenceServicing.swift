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
    func save(data: any Persistable) async
    func fetch<T: Persistable>(predicate: Predicate<T>?,
                              sortingDescriptor: [SortDescriptor<T>]) async throws -> [T]
    func fetch<T: Persistable>(identifier: PersistentIdentifier) async -> T?
    func fetchOne<T: Persistable>(predicate: Predicate<T>) async throws -> T?
    func fetchAll<T: Persistable>() async throws -> [T]
    func delete(element: any Persistable) async
    func deleteAll(dataTypes: [any Persistable.Type]) async throws
    func batchSave(content: [any Persistable], batchSize: Int) async throws
}

public extension PersistenceServicing {
    func fetch<T: Persistable>(predicate: Predicate<T>? = nil,
                              sortingDescriptor: [SortDescriptor<T>] = []) async throws -> [T] {
        try await fetch(predicate: predicate, sortingDescriptor: sortingDescriptor)
    }

    func batchSave(content: [any Persistable], batchSize: Int = 100) async throws {
        try await batchSave(content: content, batchSize: batchSize)
    }
}

//
//  PersistenceError.swift
//
//
//  Created by Martin Lukacs on 02/12/2023.
//

import Foundation

///  An enumeration of custom error types for handling persistence-related errors.
/// - Cases:
///  - `noSchema`: Indicates that no schema is available.
public enum PersistenceError: Error {
    case noSchema
}

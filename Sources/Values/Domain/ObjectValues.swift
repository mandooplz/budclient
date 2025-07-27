//
//  ObjectID.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation
import Collections


// MARK: Values
public struct ObjectID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
    
    // MARK: core
    public init(_ fromString: String) throws(Error) {
        guard let value = UUID(uuidString: fromString) else {
            throw Error.invalidUUIDString
        }
        self.value = value
    }
    
    
    // MARK: operator
    package func encode() -> [String: Any] {
        ["value": value.uuidString]
    }
    
    
    // MARK: value
    public enum Error: String, Swift.Error {
        case invalidUUIDString
    }
}

// MARK: ObjectRole
public enum ObjectRole: String, Sendable, Codable {
    case root
    case node
}


// MARK: StateID
public struct StateID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


// MARK: AccessLevel
public enum AccessLevel: String, Sendable, Hashable, CaseIterable, Identifiable, Codable {
    case readOnly, readAndWrite
    
    public var id: String {
        self.rawValue
    }
}


// MARK: SetterID
public struct SetterID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


public struct GetterID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}



// MARK: GetterID
public struct ActionID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}


// MARK: ObjectTypeID
public struct ObjectTypeID: IDRepresentable {
    public let value: UUID
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
}



// MARK: Handler
package struct Handler<Event>: Sendable where Event: Sendable {
    package let routine: @Sendable (Event) -> Void
    
    package func execute(_ event: Event) {
        self.routine(event)
    }
    
    package init(_ routine: @Sendable @escaping (Event) -> Void) {
        self.routine = routine
    }
}



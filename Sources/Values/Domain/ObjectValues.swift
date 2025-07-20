//
//  ObjectID.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: Values
public struct ObjectID: IDRepresentable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
    
    public init(_ fromString: String) throws(Error) {
        guard let value = UUID(uuidString: fromString) else {
            throw Error.invalidUUIDString
        }
        self.value = value
    }
    
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
public enum AccessLevel: String, Sendable, Hashable, CaseIterable, Identifiable {
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


// MARK: ValueTypeID
public struct ValueTypeID: IDRepresentable {
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







// MARK: StateValue
public struct StateValue: Sendable {
    public let name: String
    public let isOptional: Bool
    public let type: ValueTypeID
    
    public init(name: String, isOptional: Bool = false, type: ValueTypeID = .init()) {
        self.name = name
        self.isOptional = isOptional
        self.type = type
    }
    
    public static let AnyValue = StateValue.init(name: "Any")
}


// MARK: ParameterValue
public struct ParameterValue: Sendable, Hashable {
    public let name: String
    public let isOptional: Bool
    public let type: ValueTypeID
    
    public init(name: String, isOptional: Bool = false, type: ValueTypeID = .init()) {
        self.name = name
        self.isOptional = isOptional
        self.type = type
    }
    
    public static let AnyValue = ParameterValue(name: "AnyValue")
}


// MARK: ResultValue
public struct ResultValue: Sendable, Hashable {
    public let name: String
    public let isOptional: Bool
    public let type: ValueTypeID
    
    public init(name: String, isOptional: Bool = false, type: ValueTypeID = .init()) {
        self.name = name
        self.isOptional = isOptional
        self.type = type
    }
    
    public static let AnyValue = ResultValue(name: "AnyValue")
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



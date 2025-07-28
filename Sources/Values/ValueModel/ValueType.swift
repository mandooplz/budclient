//
//  ValueType.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation
import Collections
import BudMacro


// MARK: ValueID
@ShowState
public struct ValueID: Sendable, Hashable, Codable {
    public let value: UUID
    
    // MARK: core
    public init(_ value: UUID = UUID()) {
        self.value = value
    }
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            Self.value: self.value
        ]
    }
}

package extension ValueID {
    static let stringValue: Self = .init()
    static let intValue: Self = .init()
    static let floatValue: Self = .init()
    static let voidValue: Self = .init()
}




// MARK: StateValue
@ShowState
public struct StateValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueID?
    
    // MARK: core
    public init(name: String,
                type: ValueID? = nil) {
        self.name = name
        self.type = type
    }
    
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            Self.name : self.name,
            Self.type: self.type ?? NSNull()
        ]
    }
}


// MARK: ParameterValue
@ShowState
public struct ParameterValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueID?
    
    // MARK: core
    public init(name: String,
                type: ValueID? = nil) {
        self.name = name
        self.type = type
    }
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            Self.name: self.name,
            Self.type: self.type ?? NSNull()
        ]
    }
}

package extension Array<ParameterValue> {
    func encode() -> [[String: Any]] {
        self.map { $0.encode() }
    }
}


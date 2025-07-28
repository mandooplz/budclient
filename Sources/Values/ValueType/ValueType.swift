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
// ValueModel, ValueSource가 관리하는 특정 값을 의미한다.
// String, Int, Float
// Array<Int>, Array<String> -> 모두 동일한 ValueID를 갖는다.
@ShowState
public struct ValueID: Sendable, Hashable, Codable {
    public let value: String
    
    // MARK: core
    public init(_ value: String = UUID().uuidString) {
        self.value = value
    }
    
    package func encode() -> [String: Any] {
        [
            Self.value: self.value
        ]
    }
}


// MARK: ValueType
@ShowState
public struct ValueType: Sendable, Hashable, Codable {
    public let id: ValueID
    public let name: String // 굳이 이름이 필요한가?
    public let isOptional: Bool
    public let description: String?
    public let associatedTypes: [ValueType]
    public var isGeneric: Bool { associatedTypes.count > 0 }
    
    
    // MARK: core
    package init(id: ValueID = .init(),
                name: String,
                isOptional: Bool = false,
                description: String? = nil,
                associatedTypes: [ValueType] = []) {
        self.id = id
        self.name = name
        self.isOptional = isOptional
        self.description = description
        self.associatedTypes = associatedTypes
    }
    
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            ValueType.id: self.id.encode(),
            ValueType.name: self.name,
            ValueType.isOptional: self.isOptional,
            ValueType.description: self.description as Any,
            ValueType.associatedTypes: self.associatedTypes.map { $0.encode() },
            ValueType.isGeneric: self.isGeneric
        ]
    }
}

extension ValueType {
    public static let void = ValueType(id: .init("VOID"),
                                       name: "void")
    public static let anyValue = ValueType(id: .init("ANY"),
                                           name: "AnyValue")
    public static let stringValue = ValueType(id: .init("STRING"),
                                              name: "String")
    public static let intValue = ValueType(id: .init("INT"),
                                              name: "Int")
}



// MARK: StateValue
@ShowState
public struct StateValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    // MARK: core
    public init(name: String, type: ValueType) {
        self.name = name
        self.type = type
    }
    
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            Self.name : self.name,
            Self.type: self.type.encode()
        ]
    }
}

public extension StateValue {
    static var anyState: StateValue {
        Self (name: "anyState", type: .anyValue)
    }
}


@ShowState
public struct ParameterValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    // MARK: core
    public init(name: String, type: ValueType) {
        self.name = name
        self.type = type
    }
    
    // MARK: operator
    package func encode() -> [String: Any] {
        [
            Self.name: self.name,
            Self.type: self.type.encode()
        ]
    }
}

public extension ParameterValue {
    static let anyParameter = ParameterValue(name: "anyParameter", type: .anyValue)
}

public extension OrderedSet<ParameterValue> {
    func encode() -> [[String: Any]] {
        self.map { $0.encode() }
    }
    
    func toDictionary() -> OrderedDictionary<ParameterValue, ValueID> {
        OrderedDictionary(uniqueKeys: self,
                          values: self.map { $0.type.id })
    }
}




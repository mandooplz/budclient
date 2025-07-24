//
//  ValueType.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation
import Collections


// MARK: ValueID
// ValueModel, ValueSource가 관리하는 특정 값을 의미한다.
// String, Int, Float
// Array<Int>, Array<String> -> 모두 동일한 ValueID를 갖는다. 
public struct ValueID: Sendable, Hashable, Codable {
    public let value: String
    
    // MARK: core
    public init(_ value: String = UUID().uuidString) {
        self.value = value
    }
}


// MARK: ValueType
public struct ValueType: Sendable, Hashable, Codable {
    public let id: ValueID
    public let name: String
    public let isOptional: Bool
    public let description: String?
    public let associatedTypes: [ValueType]
    public var isGeneric: Bool { associatedTypes.count > 0 }
    
    
    // MARK: core
    public static let void = ValueType(id: .init("VOID"),
                                       name: "void")
    public static let anyValue = ValueType(id: .init("ANY"),
                                           name: "AnyValue")
    public static let stringValue = ValueType(id: .init("STRING"),
                                              name: "String")
    public static let intValue = ValueType(id: .init("INT"),
                                              name: "Int")
    
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
    
}



// MARK: StateValue
public struct StateValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    public init(name: String, type: ValueType) {
        self.name = name
        self.type = type
    }
    
    public static let anyState = Self (name: "anyState", type: .anyValue)
}


// idAdult(name: String, age: Int) 에서 ParameterValue가 이 값에 해당한다. 
public struct ParameterValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    public init(name: String, type: ValueType) {
        self.name = name
        self.type = type
    }
    
    public static let anyParameter = Self (name: "anyParameter", type: .anyValue)
}

public extension OrderedSet<ParameterValue> {
    func toDictionary() -> OrderedDictionary<ParameterValue, ValueID> {
        OrderedDictionary(uniqueKeys: self,
                          values: self.map { $0.type.id })
    }
}




//
//  ValueType.swift
//  BudClient
//
//  Created by 김민우 on 7/23/25.
//
import Foundation


// MARK: ValueID
// ValueModel, ValueSource가 관리하는 특정 값을 의미한다.
// String, Int, Float, Array<T,S> ->
public struct ValueID: Sendable, Hashable, Codable {
    public let value: UUID
    
    public init(_ value: UUID = UUID()) {
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
    public var isGeneric: Bool { associatedTypes.isEmpty == false }
    
    public init(id: ValueID, name: String, isOptional: Bool, description: String, associatedTypes: [ValueType] = []) {
        self.id = id
        self.name = name
        self.isOptional = isOptional
        self.description = description
    }
}



// MARK: StateValue
public struct StateValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    public init(name: String, type: any ValueTypeRepresentable) {
        self.name = name
        self.type = type
    }
}


public struct ParameterValue: Sendable, Hashable, Codable {
    public let name: String
    public let type: ValueType
    
    public init(name: String, type: ValueType) {
        self.name = name
        self.type = type
    }
}




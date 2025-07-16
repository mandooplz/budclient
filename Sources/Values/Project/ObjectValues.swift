//
//  ObjectValues.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation


// MARK: ObjectRole
public enum ObjectRole: String, Sendable, Codable {
    case root
    case node
}


// MARK: AccessLevel
public enum AccessLevel: String, Sendable, Hashable, CaseIterable, Identifiable {
    case readOnly, readAndWrite
    
    public var id: String {
        self.rawValue
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

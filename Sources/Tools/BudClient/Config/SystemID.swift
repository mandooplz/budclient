//
//  SystemID.swift
//  BudClient
//
//  Created by 김민우 on 7/1/25.
//
import Foundation


// MARK: SystemID
public struct SystemID: Sendable, Hashable {
    public let value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
    
    public var toString: String {
        value.uuidString
    }
}

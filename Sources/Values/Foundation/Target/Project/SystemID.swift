//
//  SystemID.swift
//  BudClient
//
//  Created by 김민우 on 7/4/25.
//
import Foundation


// MARK: SystemID
public struct SystemID: Identity {
    public let value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
}

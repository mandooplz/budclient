//
//  SystemSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation


// MARK: SystemSourceID
public struct SystemSourceID: Identity {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(uuid: UUID = UUID()) {
        self.value = uuid.uuidString
    }
}

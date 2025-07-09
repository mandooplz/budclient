//
//  ValueSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation


// MARK: ValueSourceID
public struct ValueSourceID: Identity {
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init() {
        self.value = UUID().uuidString
    }
}

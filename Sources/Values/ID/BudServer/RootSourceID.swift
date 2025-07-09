//
//  RootSourceID.swift
//  BudClient
//
//  Created by 김민우 on 7/9/25.
//
import Foundation


// MARK: RootSourceID
public struct RootSourceID: Identity {
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
    
    public init() {
        self.value = UUID().uuidString
    }
}

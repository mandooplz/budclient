//
//  PushProjectSourceName.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//


// MARK: PushProjectSourceName
public struct PushProjectSourceName: Ticket {
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
}

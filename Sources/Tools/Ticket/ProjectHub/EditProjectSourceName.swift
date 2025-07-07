//
//  EditProjectNameTicket.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//


// MARK: EditProjectSourceName
public struct EditProjectSourceName: Ticket {
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
}

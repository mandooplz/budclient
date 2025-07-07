//
//  CreateProjectTicket.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: CreateProjectTicket
public struct CreateProjectTicket: Sendable, Hashable {
    public let creator: UserID
    public let target: ProjectID
    public let name: String
    
    public init(creator: UserID, target: ProjectID, name: String) {
        self.creator = creator
        self.target = target
        self.name = name
    }
}


// MARK: EditProjectNameTicket
public struct EditProjectNameTicket: Sendable, Hashable {
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
}

//
//  Ticket.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//
import Foundation


// MARK: Ticket
public struct Ticket: Sendable, Hashable {
    public let system: SystemID
    public let user: UserID
    
    public init(system: SystemID, user: UserID) {
        self.system = system
        self.user = user
    }
}


public struct ProjectTicket: Sendable, Hashable {
    public let system: SystemID
    public let user: UserID
    public let projectName: String
    
    public init(system: SystemID, user: UserID, projectName: String) {
        self.system = system
        self.user = user
        self.projectName = projectName
    }
}

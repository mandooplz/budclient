//
//  Ticket.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//
import Foundation


// MARK: Ticket
public struct SetHandlerTicket: Sendable, Hashable {
    public let object: ObjectID
    public let target: ProjectID
    
    public init(object: ObjectID, target: ProjectID) {
        self.object = object
        self.target = target
    }
}




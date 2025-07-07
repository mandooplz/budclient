//
//  Ticket.swift
//  BudClient
//
//  Created by 김민우 on 7/2/25.
//


// MARK: SubscrieProjectSource
public struct SubscrieProjectSource: Ticket {
    public let object: ObjectID
    public let target: ProjectID
    
    public init(object: ObjectID, target: ProjectID) {
        self.object = object
        self.target = target
    }
}




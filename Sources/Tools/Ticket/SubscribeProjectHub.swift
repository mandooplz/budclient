//
//  SubscribeProjectHub.swift
//  BudClient
//
//  Created by 김민우 on 7/7/25.
//



// MARK: SubscribeProjectHub
public struct SubscribeProjectHub: Ticket {
    public let object: ObjectID
    public let user: UserID
    
    public init(object: ObjectID, user: UserID) {
        self.object = object
        self.user = user
    }
}

//
//  CreateProjectTicket.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//


// MARK: CreateProjectTicket
public struct CreateProjectSource: Ticket {
    public let creator: UserID
    public let target: ProjectID
    public let name: String
    
    public init(creator: UserID,
                target: ProjectID = ProjectID(),
                name: String) {
        self.creator = creator
        self.target = target
        self.name = name
    }
}


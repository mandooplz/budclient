//
//  ProjectTicket.swift
//  BudClient
//
//  Created by 김민우 on 7/3/25.
//
import Foundation


// MARK: ProjecTicket
public struct ProjectTicket: Sendable, Hashable {
    public let system: SystemID
    public let user: UserID
    public let name: String
    
    public init(system: SystemID, user: UserID, name: String) {
        self.system = system
        self.user = user
        self.name = name
    }
}

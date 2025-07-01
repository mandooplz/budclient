//
//  ProjectHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@BudServer
internal final class ProjectHubMock: Sendable {
    // MARK: core
    internal static let shared = ProjectHubMock()
    internal init() { }
    
    
    // MARK: state
    internal var projectSources: Set<ProjectSourceMock.ID> = []
    internal func getMyProjectSources(userId: String) -> [ProjectSourceMock.ID] {
        projectSources
            .compactMap { $0.ref }
            .filter { $0.userId == userId }
            .map { $0.id }
    }
    
    internal var tickets: Set<Ticket> = []
    
    internal var notifiers: [UserID: Notifier] = [:]
    
    
    // MARK: action
    internal func processTickets() async {
        // mutate
        for ticket in tickets {
            switch ticket.purpose {
            case .createProjectSource:
                let projectSourceRef = ProjectSourceMock(projectHubRef: self, userId: ticket.userId)
                projectSources.insert(projectSourceRef.id)
                
                let addHandler = notifiers[ticket.userId]?.added
                addHandler?(projectSourceRef.id.value.uuidString)
                
                tickets.remove(ticket)
            }
        }
    }
    
    
    // MARK: value
    internal struct Ticket: Sendable, Hashable {
        let value: UUID
        let userId: String
        let purpose: Purpose
        
        init(userId: String, for purpose: Purpose) {
            self.value = UUID()
            self.userId = userId
            self.purpose = purpose
        }
        
        enum Purpose {
            case createProjectSource
        }
    }
    internal struct Notifier: Sendable {
        let added: Handler
        let removed: Handler
        
        typealias Handler = @Sendable (ProjectSourceID) -> Void
        typealias ProjectSourceID = String
    }
    internal typealias UserID = String
}


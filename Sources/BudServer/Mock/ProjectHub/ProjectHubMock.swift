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
    
    
    // MARK: action
    internal func processTickes() async {
        // mutate
        for ticket in tickets {
            switch ticket.purpose {
            case .createProjectSource:
                let projectSourceRef = ProjectSourceMock(projectHubRef: self, userId: ticket.userId)
                projectSources.insert(projectSourceRef.id)
                tickets.remove(ticket)
            }
        }
    }
    
    
    // MARK: action
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
}


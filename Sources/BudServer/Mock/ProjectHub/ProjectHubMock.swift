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
    internal func getProjectSources(user: UserID) -> [ProjectSourceMock.ID] {
        projectSources
            .compactMap { $0.ref }
            .filter { $0.userId == user }
            .map { $0.id }
    }
    
    internal var tickets: Set<Ticket> = []
    
    internal var notifiers: [SystemID: Notifier] = [:]
    
    
    // MARK: action
    internal func createProjectSource() async {
        // mutate
        for ticket in tickets {
            let projectSourceRef = ProjectSourceMock(
                projectHubRef: self,
                userId: ticket.user)
            projectSources.insert(projectSourceRef.id)
            
            let addHandler = notifiers[ticket.system]?.added
            addHandler?(projectSourceRef.id.value.uuidString)
            
            tickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    internal struct Notifier: Sendable {
        let added: Handler
        let removed: Handler
        
        typealias Handler = @Sendable (ProjectSourceID) -> Void
        typealias ProjectSourceID = String
    }
    internal typealias UserID = String
}


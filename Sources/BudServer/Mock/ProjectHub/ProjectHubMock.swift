//
//  ProjectHubMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@Server
final class ProjectHubMock: ServerObject {
    // MARK: core
    static let shared = ProjectHubMock()
    init() { }
    
    
    // MARK: state
    nonisolated let id: ID = ID(value: UUID())
    
    var projectSources: Set<ProjectSourceMock.ID> = []
    func getProjectSources(user: UserID) -> [ProjectSourceMock.ID] {
        projectSources
            .compactMap { $0.ref }
            .filter { $0.user == user }
            .map { $0.id }
    }
    
    var tickets: Set<ProjectTicket> = []
    
    var eventHandlers: [SystemID: Handler<ProjectHubEvent>] = [:]
    
    
    // MARK: action
    func createProjectSource() async {
        // mutate
        for ticket in tickets {
            let projectSourceRef = ProjectSourceMock(
                projectHubRef: self,
                user: ticket.user,
                name: ticket.projectName)
            let projectSource = projectSourceRef.id.value.uuidString
            projectSources.insert(projectSourceRef.id)
            
            let eventHandler = eventHandlers[ticket.system]
            let event = ProjectHubEvent.added(projectSource)
            
            eventHandler?(event)
            
            tickets.remove(ticket)
        }
    }
    
    
    // MARK: value
    struct ID: ServerObjectID {
        let value: UUID
        typealias Object = ProjectHubMock
        typealias Manager = ProjectHubMockManager
    }
}


// MARK: ObjectManager
@Server
final class ProjectHubMockManager: ServerObjectManager {
    static var container: [ProjectHubMock.ID : ProjectHubMock] = [:]
}

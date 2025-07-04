//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Tools


// MARK: Object
@Server
package final class ProjectSourceMock: Sendable {
    // MARK: core
    package init(projectHubRef: ProjectHubMock,
         user: UserID,
         name: String) {
        self.projectHubRef = projectHubRef
        self.user = user
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    package func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    package nonisolated let id = ProjectSourceID()
    package nonisolated let projectHubRef: ProjectHubMock
    private typealias Manager = ProjectSourceMockManager
    
    package var user: UserID
    package var name: String
    
    package var ticket: ProjectTicket?
    package var eventHandlers: [SystemID: Handler<ProjectSourceEvent>] = [:]
    
    
    // MARK: action
    package func processTicket() {
        // mutate
        guard Manager.isExist(id) else { return }
        guard let ticket else { return }
        for (_, handler) in eventHandlers {
            handler.execute(.modified(ticket.name))
        }
        self.ticket = nil
    }
    package func remove() {
        // mutate
        guard Manager.isExist(id) else { return }
        let event = ProjectHubEvent.removed(id)
        for (_, eventHandler) in projectHubRef.eventHandlers {
            eventHandler.execute(event)
        }
        
        projectHubRef.projectSources.remove(self.id)
        self.delete()
    }
}


// MARK: Object Manager
@Server
package final class ProjectSourceMockManager: Sendable {
    // MARK: state
    static var container: [ProjectSourceID: ProjectSourceMock] = [:]
    static func register(_ object: ProjectSourceMock) {
        container[object.id] = object
    }
    static func unregister(_ id: ProjectSourceID) {
        container[id] = nil
    }
    package static func get(_ id: ProjectSourceID) -> ProjectSourceMock? {
        container[id]
    }
    package static func isExist(_ id: ProjectSourceID) -> Bool {
        container[id] != nil
    }
}

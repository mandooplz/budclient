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
                 target: ProjectID,
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
    package nonisolated let id = ID()
    package nonisolated let target: ProjectID
    package nonisolated let projectHubRef: ProjectHubMock
    private typealias Manager = ProjectSourceMockManager
    
    package var user: UserID
    package var name: String
    
    package var ticket: ProjectTicket?
    package var eventHandlers: [SystemID: Handler<ProjectSourceEvent>] = [:]
    
    
    // MARK: action
    package func processTicket() {
        // mutate
        guard id.isExist else { return }
        guard let ticket else { return }
        for (_, handler) in eventHandlers {
            handler.execute(.modified(ticket.name))
        }
        self.ticket = nil
    }
    package func remove() {
        // mutate
        guard id.isExist else { return }
        let event = ProjectHubEvent.removed(target)
        for (_, eventHandler) in projectHubRef.eventHandlers {
            eventHandler.execute(event)
        }
        
        projectHubRef.projectSources.remove(self.id)
        self.delete()
    }
    
    
    // MARK: value
    @Server
    package struct ID: Sendable, Hashable {
        let value: UUID = UUID()
        
        var isExist: Bool {
            ProjectSourceMockManager.container[self] != nil
        }
        package var ref: ProjectSourceMock? {
            ProjectSourceMockManager.container[self]
        }
    }
}


// MARK: Object Manager
@Server
fileprivate final class ProjectSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
    fileprivate static func register(_ object: ProjectSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSourceMock.ID) {
        container[id] = nil
    }
}

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
final class ProjectSourceMock: ServerObject {
    // MARK: core
    init(projectHubRef: ProjectHubMock,
         user: String,
         name: String) {
        self.id = ID()
        self.projectHubRef = projectHubRef
        self.user = user
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let projectHubRef: ProjectHubMock
    var user: String // user
    
    var name: String
    var ticket: ProjectTicket?
    
    var eventHandlers: [SystemID: Handler<ProjectSourceEvent>] = [:]
    
    
    // MARK: action
    func processTicket() {
        // mutate
        guard let ticket else { return }
        for (_, handler) in eventHandlers {
            handler.execute(.modified(ticket.name))
        }
        self.ticket = nil
    }
    
    func remove() {
        // mutate
        // Notifier
        let event = ProjectHubEvent.removed(id.value.uuidString)
        for (_, eventHandler) in projectHubRef.eventHandlers {
            eventHandler.execute(event)
        }
        projectHubRef.projectSources.remove(self.id)
        self.delete()
    }
    
    
    // MARK: value
    @Server
    struct ID: ServerObjectID {
        let value: UUID
        init(value: UUID = UUID()) {
            self.value = value
        }
        init(_ stringValue: String) {
            self.value = UUID(uuidString: stringValue)!
        }
        typealias Object = ProjectSourceMock
        typealias Manager = ProjectSourceMockManager
    }
}


// MARK: Object Manager
@Server
final class ProjectSourceMockManager: ServerObjectManager {
    // MARK: state
    static var container: [ProjectSourceMock.ID: ProjectSourceMock] = [:]
}

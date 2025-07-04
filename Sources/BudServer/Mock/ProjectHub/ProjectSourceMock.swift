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
final class ProjectSourceMock: Sendable {
    // MARK: core
    init(projectHubRef: ProjectHubMock,
         user: UserID,
         name: String) {
        self.projectHubRef = projectHubRef
        self.user = user
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    nonisolated let id = ProjectSourceID()
    nonisolated let projectHubRef: ProjectHubMock
    private typealias Manager = ProjectSourceMockManager
    
    var user: UserID
    var name: String
    
    var ticket: ProjectTicket?
    var eventHandlers: [SystemID: Handler<ProjectSourceEvent>] = [:]
    
    
    // MARK: action
    func processTicket() {
        // mutate
        guard Manager.isExist(id) else { return }
        guard let ticket else { return }
        for (_, handler) in eventHandlers {
            handler.execute(.modified(ticket.name))
        }
        self.ticket = nil
    }
    func remove() {
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
final class ProjectSourceMockManager: Sendable {
    // MARK: state
    static var container: [ProjectSourceID: ProjectSourceMock] = [:]
    static func register(_ object: ProjectSourceMock) {
        container[object.id] = object
    }
    static func unregister(_ id: ProjectSourceID) {
        container[id] = nil
    }
    static func get(_ id: ProjectSourceID) -> ProjectSourceMock? {
        container[id]
    }
    static func isExist(_ id: ProjectSourceID) -> Bool {
        container[id] != nil
    }
}

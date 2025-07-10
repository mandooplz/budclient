//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class ProjectSourceMock: Sendable {
    // MARK: core
    package init(projectHubRef: ProjectHubMock,
                 target: ProjectID,
                 creator: UserID,
                 name: String) {
        self.target = target
        self.projectHubRef = projectHubRef
        self.creator = creator
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    package func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    package nonisolated let id = ProjectSourceID()
    package nonisolated let target: ProjectID
    package nonisolated let projectHubRef: ProjectHubMock
    private typealias Manager = ProjectSourceMockManager
    
    package var creator: UserID
    package var name: String
    
    package var systems: Set<SystemSourceID> = []
    
    package var eventHandlers: [ObjectID: Handler<ProjectSourceEvent>] = [:]
    
    
    // MARK: action
    package func remove() {
        // mutate
        guard Manager.isExist(id) else { return }
        
        let event = ProjectHubEvent.removed(target)
        for (_, eventHandler) in projectHubRef.eventHandlers {
            eventHandler.execute(event)
        }
        
        projectHubRef.projectSources.remove(self.id)
        self.delete()
    }
    package func createFirstSystem() {
        // mutate
        guard systems.isEmpty else { return }
        let systemSourceRef = SystemSourceMock(location: .origin,
                                               name: "First System")
        self.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(id: systemSourceRef.id,
                                    target: systemSourceRef.target,
                                    name: systemSourceRef.name,
                                    location: systemSourceRef.location)
        
        for (_, handler) in eventHandlers {
            handler.execute(.added(diff))
        }
    }
}


// MARK: Object Manager
@Server
package final class ProjectSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ProjectSourceID: ProjectSourceMock] = [:]
    fileprivate static func register(_ object: ProjectSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ProjectSourceID) {
        container[id] = nil
    }
    package static func get(_ id: ProjectSourceID) -> ProjectSourceMock? {
        container[id]
    }
    package static func isExist(_ id: ProjectSourceID) -> Bool {
        container[id] != nil
    }
}

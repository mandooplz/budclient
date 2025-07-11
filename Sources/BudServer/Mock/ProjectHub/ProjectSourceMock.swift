//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "ProjectSourceMock")


// MARK: Object
@Server
package final class ProjectSourceMock: ProjectSourceInterface {
    // MARK: core
    package init(projectHub: ProjectHubMock.ID,
                 target: ProjectID,
                 creator: UserID,
                 name: String) {
        self.target = target
        self.projectHub = projectHub
        self.creator = creator
        self.name = name
        
        ProjectSourceMockManager.register(self)
    }
    package func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target: ProjectID
    nonisolated let projectHub: ProjectHubMock.ID
    
    private(set) var systems: Set<SystemSourceMock.ID> = []
    package var creator: UserID
    
    private(set) var name: String
    package func setName(_ value: String) {
        self.name = value
        logger.success(value)
    }
    
    private(set) var eventHandlers: [ObjectID: Handler<ProjectSourceEvent>] = [:]
    package func hasHandler(requester: ObjectID) async -> Bool {
        eventHandlers[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<ProjectSourceEvent>) {
        eventHandlers[requester] = handler
    }
    package func removeHandler(requester: ObjectID) async {
        eventHandlers[requester] = nil
    }
    
    
    
    // MARK: action
    package func createFirstSystem() {
        // mutate
        guard systems.isEmpty else { return }
        let systemSourceRef = SystemSourceMock(name: "First System",
                                               location: .origin,
                                               parent: self.id)
        self.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(id: systemSourceRef.id,
                                    target: systemSourceRef.target,
                                    name: systemSourceRef.name,
                                    location: systemSourceRef.location)
        let workflow = WorkFlow.id
        
        for (_, handler) in eventHandlers {
            handler.execute(.added(diff), workflow)
        }
    }
    package func remove() {
        // mutate
        guard id.isExist else { return }
        guard let projectHubRef = projectHub.ref else { return }
        
        let diff = ProjectSourceDiff(id: self.id,
                                     target: self.target,
                                     name: self.name)
        let workflow = WorkFlow.id

        for (_, eventHandler) in projectHubRef.eventHandlers {
            eventHandler.execute(.removed(diff), workflow)
        }
        
        projectHubRef.projectSources.remove(self.id)
        self.delete()
    }
    
    
    // MARK: value
    @Server
    package struct ID: ProjectSourceIdentity {
        let value: UUID = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
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

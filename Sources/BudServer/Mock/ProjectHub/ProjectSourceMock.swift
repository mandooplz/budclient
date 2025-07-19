//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values

private let logger = BudLogger("ProjectSourceMock")


// MARK: Object
@Server
package final class ProjectSourceMock: ProjectSourceInterface {
    // MARK: core
    package init(name: String,
                 creator: UserID,
                 projectHubMockRef: ProjectHubMock.ID) {
        self.name = name
        self.creator = creator
        self.projectHub = projectHubMockRef
        self.target = ProjectID()
        
        ProjectSourceMockManager.register(self)
    }
    package func delete() {
        ProjectSourceMockManager.unregister(self.id)
    }
    
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target: ProjectID
    nonisolated let projectHub: ProjectHubMock.ID
    
    var systems: Set<SystemSourceMock.ID> = []
    func isLocationExist(_ location: Location) -> Bool {
        self.systems
            .compactMap { $0.ref }
            .contains { $0.location == location }
    }
    
    private(set) var name: String
    package func setName(_ value: String) {
        self.name = value
    }
    
    package var creator: UserID
    
    var handler: EventHandler?
    package func setHandler(_ handler: EventHandler) {
        self.handler = handler
    }
    
    package func notifyNameChanged() {
        let diff = ProjectSourceDiff(id: self.id,
                                     target: self.target,
                                     name: self.name)
        
        handler?.execute(.modified(diff))
    }
    
    
    // MARK: action
    package func createSystem() {
        // mutate
        guard systems.isEmpty else { return }
        
        
        let systemSourceRef = SystemSourceMock(name: "First System",
                                               location: .origin,
                                               parent: self.id)
        
        self.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(systemSourceRef)
        self.handler?.execute(.added(diff))
    }
    package func removeProject() {
        // mutate
        guard id.isExist else { return }
        guard let projectHubRef = projectHub.ref else { return }
        
        let diff = ProjectSourceDiff(id: self.id,
                                     target: self.target,
                                     name: self.name)

        handler?.execute(.removed(diff))
        
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
    package typealias EventHandler = Handler<ProjectSourceEvent>
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

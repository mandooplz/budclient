//
//  ProjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 6/30/25.
//
import Foundation
import Values
import Collections



// MARK: Object
@Server
package final class ProjectSourceMock: ProjectSourceInterface {
    // MARK: core
    private let logger = BudLogger("ProjectSourceMock")
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
    
    var createdAt: Date = .now
    var updatedAt: Date = .now
    var order: Int = 0
    
    private(set) var name: String
    package var creator: UserID
    
    var syncQyeye: Deque<ObjectID> = []
    var systems: Set<SystemSourceMock.ID> = []
    var values: [ValueID:ValueSourceMock.ID] = [:]
    
    var handlers = [ObjectID: EventHandler]()
    
    
    func isLocationExist(_ location: Location) -> Bool {
        self.systems
            .compactMap { $0.ref }
            .contains { $0.location == location }
    }
    package func setName(_ value: String) {
        self.name = value
    }
    package func registerSync(_ object: ObjectID) async {
        self.syncQyeye.append(object)
    }
    
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) {
        logger.start()
        
        handlers[requester] = handler
    }
    
    
    // MARK: action
    package func synchronize() {
        logger.start()
        
        let diffs = self.systems
            .compactMap { $0.ref }
            .map { SystemSourceDiff($0) }
        
        for handler in self.handlers.values {
            diffs.forEach { handler.execute(.systemAdded($0)) }
        }
    }
    package func notifyStateChanged() {
        logger.start()
        
        let diff = ProjectSourceDiff(self)
        
        handlers.values.forEach { eventHandler in
            eventHandler.execute(.modified(diff))
        }
    }
    
    package func createSystem() {
        // capture
        guard systems.isEmpty else {
            logger.failure("이미 (0,0) 위치에 SystemSource가 존재합니다.")
            return
        }
        
        // mutate
        let systemSourceRef = SystemSourceMock(name: "First System",
                                               location: .origin,
                                               parent: self.id)
        
        self.systems.insert(systemSourceRef.id)
        
        
        // notify
        let diff = SystemSourceDiff(systemSourceRef)
        
        handlers.values.forEach { handler in
            handler.execute(.systemAdded(diff))
        }
        
        
    }
    package func createValue() {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ProjectSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        let newValueSourceRef = ValueSourceMock(owner: self.id)
        self.values[newValueSourceRef.target] = newValueSourceRef.id
        
        // notify
        let diff = ValueSourceDiff(newValueSourceRef)
        self.handlers.values
            .forEach { $0.execute(.valueAdded(diff)) }
    }
    
    package func removeProject() {
        // capture
        guard id.isExist else { return }
        guard let projectHubRef = projectHub.ref else { return }
        
        // mutate
        projectHubRef.projectSources.remove(self.id)
        self.delete()
        
        // notify
        handlers.values.forEach { handler in
            handler.execute(.removed)
        }
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

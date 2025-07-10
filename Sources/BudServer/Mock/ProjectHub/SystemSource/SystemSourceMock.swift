//
//  SystemSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values


// MARK: Object
@Server
package final class SystemSourceMock: Sendable {
    // MARK: core
    init(name: String,
         location: Location,
         parent: ProjectSourceID,
         target: SystemID = SystemID()) {
        self.name = name
        self.location = location
        self.parent = parent
        self.target = target
        
        SystemSourceMockManager.register(self)
    }
    func delete() {
        SystemSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id = SystemSourceID()
    nonisolated let target: SystemID
    nonisolated let parent: ProjectSourceID
    
    package var name: String
    package var location: Location
    
    package var eventHandlers: [ObjectID: Handler<SystemSourceEvent>] = [:]
    package func hasHandler(requester: ObjectID) -> Bool {
        eventHandlers[requester] != nil
    }
    package func setHandler(requester: ObjectID, handler: Handler<SystemSourceEvent>) {
        eventHandlers[requester] = handler
    }
    package func removeHandler(requester: ObjectID) {
        eventHandlers[requester] = nil
    }
    
    package func notifyNameChanged() {
        // capture
        guard SystemSourceMockManager.isExist(id) else { return }
        guard let projectSourceRef = ProjectSourceMockManager.get(parent) else { return }
        let eventHandlers = projectSourceRef.eventHandlers
        
        let diff = SystemSourceDiff(id: id,
                                    target: target,
                                    name: name,
                                    location: location)
        
        for (_, handler) in eventHandlers {
            handler.execute(.modified(diff))
        }
    }
    
    
    // MARK: action
}


// MARK: Object Manager
@Server
package final class SystemSourceMockManager: Sendable {
    // MARK: state
    private static var container: [SystemSourceID: SystemSourceMock] = [:]
    fileprivate static func register(_ object: SystemSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSourceID) {
        container[id] = nil
    }
    package static func get(_ id: SystemSourceID) -> SystemSourceMock? {
        container[id]
    }
    package static func isExist(_ id: SystemSourceID) -> Bool {
        container[id] != nil
    }
}

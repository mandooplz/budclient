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
package final class SystemSourceMock: SystemSourceInterface {
    // MARK: core
    init(name: String,
         location: Location,
         parent: ProjectSourceMock.ID,
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
    package nonisolated let id = ID()
    let target: SystemID
    let parent: ProjectSourceMock.ID
    
    private(set) var name: String
    package func setName(_ value: String) async {
        self.name = value
    }
    
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
        guard id.isExist else { return }
        guard let projectSourceRef = parent.ref else { return }
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
    package func addSystemTop() async {
        fatalError()
    }
    package func addSystemLeft() async {
        fatalError()
    }
    package func addSystemRight() async {
        fatalError()
    }
    package func addSystemBottom() async {
        fatalError()
    }
    
    package func remove() async {
        fatalError()
    }
    
    
    // MARK: value
    @Server
    package struct ID: SystemSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            SystemSourceMockManager.container[self] != nil
        }
        package var ref: SystemSourceMock? {
            SystemSourceMockManager.container[self]
        }
    }
}


// MARK: Object Manager
@Server
fileprivate final class SystemSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [SystemSourceMock.ID: SystemSourceMock] = [:]
    fileprivate static func register(_ object: SystemSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SystemSourceMock.ID) {
        container[id] = nil
    }
}

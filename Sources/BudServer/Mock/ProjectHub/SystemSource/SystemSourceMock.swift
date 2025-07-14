//
//  SystemSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values

private let logger = WorkFlow.getLogger(for: "SystemSourceMock")


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
    package func addSystemRight() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let rightLocation = self.location.getRight()
        let projectSourceRef = self.parent.ref!
        let eventHandlers = projectSourceRef.eventHandlers
        
        // mutate
        guard projectSourceRef.isLocationExist(rightLocation) == false else {
            logger.failure("이미 오른쪽에 SystemSource가 존재합니다.")
            return
        }
        let systemSourceRef = SystemSourceMock(name: "New System",
                                               location: rightLocation,
                                               parent: self.parent)
        projectSourceRef.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(
            id: systemSourceRef.id,
            target: systemSourceRef.target,
            name: systemSourceRef.name,
            location: systemSourceRef.location)
        for (_, eventHandler) in eventHandlers {
            eventHandler.execute(.added(diff))
        }
        
    }
    package func addSystemLeft() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let leftLocation = self.location.getLeft()
        let projectSourceRef = self.parent.ref!
        let eventHandlers = projectSourceRef.eventHandlers
        
        // mutate
        guard projectSourceRef.isLocationExist(leftLocation) == false else {
            logger.failure("이미 왼쪽에 SystemSource가 존재합니다.")
            return
        }
        let systemSourceRef = SystemSourceMock(name: "New System",
                                               location: leftLocation,
                                               parent: self.parent)
        projectSourceRef.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(
            id: systemSourceRef.id,
            target: systemSourceRef.target,
            name: systemSourceRef.name,
            location: systemSourceRef.location)
        for (_, eventHandler) in eventHandlers {
            eventHandler.execute(.added(diff))
        }
    }
    package func addSystemTop() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let topLocation = self.location.getTop()
        let projectSourceRef = self.parent.ref!
        let eventHandlers = projectSourceRef.eventHandlers
        
        // mutate
        guard projectSourceRef.isLocationExist(topLocation) == false else {
            logger.failure("이미 위쪽에 SystemSource가 존재합니다.")
            return
        }
        let systemSourceRef = SystemSourceMock(name: "New System",
                                               location: topLocation,
                                               parent: self.parent)
        projectSourceRef.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(
            id: systemSourceRef.id,
            target: systemSourceRef.target,
            name: systemSourceRef.name,
            location: systemSourceRef.location)
        for (_, eventHandler) in eventHandlers {
            eventHandler.execute(.added(diff))
        }
    }
    package func addSystemBottom() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let bottomLocation = self.location.getBotttom()
        let projectSourceRef = self.parent.ref!
        let eventHandlers = projectSourceRef.eventHandlers
        
        // mutate
        guard projectSourceRef.isLocationExist(bottomLocation) == false else {
            logger.failure("이미 아래쪽에 SystemSource가 존재합니다.")
            return
        }
        let systemSourceRef = SystemSourceMock(name: "New System",
                                               location: bottomLocation,
                                               parent: self.parent)
        projectSourceRef.systems.insert(systemSourceRef.id)
        
        // notify
        let diff = SystemSourceDiff(
            id: systemSourceRef.id,
            target: systemSourceRef.target,
            name: systemSourceRef.name,
            location: systemSourceRef.location)
        for (_, eventHandler) in eventHandlers {
            eventHandler.execute(.added(diff))
        }
    }
    
    
    package func remove() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectSourceRef = self.parent.ref!
        let eventHandlers = projectSourceRef.eventHandlers
        let diff = SystemSourceDiff(id: self.id,
                                    target: self.target,
                                    name: self.name,
                                    location: self.location)
        
        // mutate
        projectSourceRef.systems.remove(self.id)
        self.delete()
        
        // notify
        for (_, eventHandler) in eventHandlers {
            eventHandler.execute(.removed(diff))
        }
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

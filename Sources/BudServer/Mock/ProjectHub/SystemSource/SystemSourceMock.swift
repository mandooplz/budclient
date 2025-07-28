//
//  SystemSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/8/25.
//
import Foundation
import Values
import Collections



// MARK: Object
@Server
package final class SystemSourceMock: SystemSourceInterface {
    // MARK: core
    private let logger = BudLogger("SystemSourceMock")
    init(name: String,
         location: Location,
         parent: ProjectSourceMock.ID,
         target: SystemID = SystemID()
    ) {
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
    
    nonisolated let createdAt = Date.now
    var updatedAt = Date.now
    var order: Int = 0
    
    private(set) var name: String
    package var location: Location
    package var objects = OrderedDictionary<ObjectID, ObjectSourceMock.ID>()
    
    var syncQueue: Deque<ObjectID> = []
    package func registerSync(_ object: ObjectID) async {
        syncQueue.append(object)
    }
    
    package func setName(_ value: String) async {
        self.name = value
    }
    
    var handlers: [ObjectID:EventHandler] = [:]
    package func appendHandler(requester: ObjectID, _ handler: Handler<SystemSourceEvent>) {
        self.handlers[requester] = handler
    }
    
    
    // MARK: action
    package func synchronize() {
        logger.start()
        
        while syncQueue.isEmpty == false {
            let object = syncQueue.removeFirst()
            guard let eventHandler = handlers[object] else {
                logger.failure("Object의 EventHandler가 존재하지 않습니다.")
                continue
            }
            
            self.objects.values
                .compactMap { $0.ref }
                .map { ObjectSourceDiff($0) }
                .forEach { eventHandler.execute(.objectAdded($0)) }
        }
    }
    package func notifyStateChanged() {
        // capture
        guard id.isExist else { return }
        
        let diff = SystemSourceDiff(self)
        
        self.handlers.values
            .forEach { $0.execute(.modified(diff))}
    }
    
    package func addSystemRight() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let rightLocation = self.location.getRight()
        let projectSourceRef = self.parent.ref!
        let projectSourceHandlers = projectSourceRef.handlers.values
        
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
        let diff = SystemSourceDiff(systemSourceRef)
        
        projectSourceHandlers.forEach { eventHandler in
            eventHandler.execute(.systemAdded(diff))
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
        let projectSourceHandlers = projectSourceRef.handlers.values
        
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
        let diff = SystemSourceDiff(systemSourceRef)
        
        projectSourceHandlers.forEach { eventHandler in
            eventHandler.execute(.systemAdded(diff))
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
        let projectSourceHandlers = projectSourceRef.handlers.values
        
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
        let diff = SystemSourceDiff(systemSourceRef)
        projectSourceHandlers.forEach { eventHandler in
            eventHandler.execute(.systemAdded(diff))
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
        let projectSourceHandlers = projectSourceRef.handlers.values
        
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
        let diff = SystemSourceDiff(systemSourceRef)
        
        projectSourceHandlers.forEach { eventHandler in
            eventHandler.execute(.systemAdded(diff))
        }
    }
    
    package func createRootObject() async {
        logger.start()
        
        // caputure
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        guard objects.isEmpty else {
            logger.failure("Root에 해당하는 ObjectSourceMock이 이미 존재합니다.")
            return
        }
        
        // mutate
        let rootObjectSourceRef = ObjectSourceMock(
            name: "New RootObject",
            role: .root,
            systemSource: self.id)
        
        self.objects[rootObjectSourceRef.target] = rootObjectSourceRef.id
        
        // notify
        let diff = ObjectSourceDiff(rootObjectSourceRef)
        self.handlers.values
            .forEach { $0.execute(.objectAdded(diff))}
    }
    
    package func removeSystem() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SystemSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let projectSourceRef = self.parent.ref!
        
        // mutate
        projectSourceRef.systems.remove(self.id)
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
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
    package typealias EventHandler = Handler<SystemSourceEvent>
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

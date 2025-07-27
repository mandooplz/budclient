//
//  ObjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("ObjectSourceMock")


// MARK: Object
@Server
package final class ObjectSourceMock: ObjectSourceInterface {
    // MARK: core
    init(name: String,
         role: ObjectRole,
         parent: ObjectID? = nil,
         systemSource: SystemSourceMock.ID) {
        self.name = name
        self.role = role
        self.parent = parent
        self.systemSource = systemSource
        
        if role == .node && parent == nil {
            logger.failure("node에 해당하는 Object의 parent가 nil일 수 없습니다.")
        } else if role == .root && parent != nil {
            logger.failure("root에 해당하는 Object의 parent가 존재해서는 안됩니다.")
        }
        
        ObjectSourceMockManager.register(self)
    }
    func delete() {
        ObjectSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let systemSource: SystemSourceMock.ID
    package nonisolated let target = ObjectID()
    
    nonisolated let createdAt: Date = .now
    var updateAt: Date = .now
    var order: Int = 0
    
    package nonisolated let role: ObjectRole
    package var parent: ObjectID!
    package var childs: OrderedSet<ObjectID> = []
    
    package var name: String
    package func setName(_ value: String) async {
        logger.start()
        
        self.name = value
    }
    
    var syncQueue: Deque<ObjectID> = []
    package func registerSync(_ object: ObjectID) async {
        self.syncQueue.append(object)
    }
    
    
    package var handlers: [ObjectID: EventHandler] = [:]
    package func appendHandler(requester: ObjectID, _ handler: EventHandler) {
        self.handlers[requester] = handler
    }
    package func notifyStateChanged() async {
        logger.start()
        
        let diff = ObjectSourceDiff(self)

        for eventHandler in self.handlers.values {
            eventHandler.execute(.modified(diff))
        }
    }
    
    
    var states: OrderedDictionary<StateID, StateSourceMock.ID> = [:]
    var actions: OrderedDictionary<ActionID, ActionSourceMock.ID> = [:]
    
    
    // MARK: action
    package func synchronize() async {
        logger.start()
        
        while syncQueue.isEmpty == false {
            let object = syncQueue.removeFirst()
            guard let eventHandler = self.handlers[object] else {
                logger.failure("Object에 해당하는 handler가 존재하지 않습니다.")
                continue
            }
            
            self.states.values
                .compactMap { $0.ref }
                .map { StateSourceDiff($0) }
                .forEach {
                    eventHandler.execute(.stateAdded($0))
                }
            
            self.actions.values
                .compactMap { $0.ref }
                .map { ActionSourceDiff($0) }
                .forEach {
                    eventHandler.execute(.actionAdded($0))
                }
        }
    }
    
    package func appendNewState() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행취소됩니다.")
            return
        }
        
        let stateSourceRef = StateSourceMock(
            name: "New State",
            owner: self.id)
        self.states[stateSourceRef.target] = stateSourceRef.id
        
        // notify
        let diff = StateSourceDiff(stateSourceRef)
        
        self.handlers.values
            .forEach { $0.execute(.stateAdded(diff)) }
    }
    package func appendNewAction() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행취소됩니다.")
            return
        }
        
        let actionSourceRef = ActionSourceMock(
            name: "New Action",
            owner: self.id)
        self.actions[actionSourceRef.target] = actionSourceRef.id
        
        // notify
        let diff = ActionSourceDiff(actionSourceRef)
        
        self.handlers.values
            .forEach { $0.execute(.actionAdded(diff)) }
    }
    
    package func createChildObject() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSourceRef = self.systemSource.ref!
        
        // mutate
        let childObjectSourceRef = ObjectSourceMock(
            name: "New Object",
            role: .node,
            parent: self.target,
            systemSource: self.systemSource)
        
        systemSourceRef.objects[childObjectSourceRef.target] = childObjectSourceRef.id
        self.childs.append(childObjectSourceRef.target)
        
        // notify
        let diff = ObjectSourceDiff(childObjectSourceRef)
        
        systemSourceRef.handlers.values
            .forEach { $0.execute(.objectAdded(diff)) }
    }
    
    package func removeObject() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let systemSourceRef = systemSource.ref!
        
        // mutate
        systemSourceRef.objects[self.target] = nil
        
        self.states.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        self.actions.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
    }

    
    
    // MARK: value
    @Server
    package struct ID: ObjectSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ObjectSourceMockManager.container[self] != nil
        }
        package var ref: ObjectSourceMock? {
            ObjectSourceMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<ObjectSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class ObjectSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ObjectSourceMock.ID: ObjectSourceMock] = [:]
    fileprivate static func register(_ object: ObjectSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ObjectSourceMock.ID) {
        container[id] = nil
    }
}

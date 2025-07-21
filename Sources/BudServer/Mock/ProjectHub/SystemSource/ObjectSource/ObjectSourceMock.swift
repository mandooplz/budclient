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
    
    package nonisolated let role: ObjectRole
    package var parent: ObjectID!
    package var childs: OrderedSet<ObjectID> = []
    
    package var name: String
    package func setName(_ value: String) async {
        logger.start()
        
        self.name = value
    }
    
    
    package var handler: EventHandler?
    package func setHandler(for requester: ObjectID, _ handler: EventHandler) {
        self.handler = handler
    }
    package func notifyNameChanged() async {
        logger.start()
        
        let diff = ObjectSourceDiff(self)
        
        self.handler?.execute(.modified(diff))
    }
    
    
    var states: [StateID: StateSourceMock.ID] = [:]
    var actions: [ActionID: ActionSourceMock.ID] = [:]
    
    package func synchronize(requester: ObjectID) async {
        logger.start()
        
        self.states.values
            .compactMap { $0.ref }
            .map { StateSourceDiff($0) }
            .forEach {
                self.handler?.execute(.addedState($0))
            }
        
        self.actions.values
            .compactMap { $0.ref }
            .map { ActionSourceDiff($0) }
            .forEach {
                self.handler?.execute(.actionAdded($0))
            }
    }
    
    // MARK: action
    package func appendNewState() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행취소됩니다.")
            return
        }
        
        let stateSourceRef = StateSourceMock(name: "New State")
        self.states[stateSourceRef.target] = stateSourceRef.id
        
        // notify
        logger.failure("새로운 StateSource 생성 notify 로직 구현 필요")
    }
    package func appendNewAction() async {
        logger.start()
        
        guard id.isExist else {
            logger.failure("ObjectSourceMock이 존재하지 않아 실행취소됩니다.")
            return
        }
        
        let actionSourceRef = ActionSourceMock(name: "New Action")
        self.actions[actionSourceRef.target] = actionSourceRef.id
        
        // notify
        logger.failure("새로운 ActionSource 생성 notify 로직 구현 필요")
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
        
        systemSourceRef.handler?.execute(.objectAdded(diff))
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

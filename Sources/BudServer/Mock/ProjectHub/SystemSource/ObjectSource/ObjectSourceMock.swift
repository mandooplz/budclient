//
//  ObjectSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values

private let logger = BudLogger("ObjectSourceMock")


// MARK: Object
@Server
package final class ObjectSourceMock: ObjectSourceInterface {
    // MARK: core
    init(name: String,
         role: ObjectRole,
         parentRef: SystemSourceMock) {
        self.name = name
        self.role = role
        self.parentRef = parentRef
        
        ObjectSourceMockManager.register(self)
    }
    func delete() {
        ObjectSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    package nonisolated let parentRef: SystemSourceMock
    package nonisolated let target = ObjectID()
    
    package nonisolated let role: ObjectRole
    
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
        self.states.values
            .compactMap { $0.ref }
            .map { StateSourceDiff($0) }
            .forEach {
                self.handler?.execute(.addedState($0))
            }
        
        logger.failure("actionDiffs 구현 필요")
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
    }
    package func appendNewAction() async {
        fatalError()
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

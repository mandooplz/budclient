//
//  ActionSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/21/25.
//
import Foundation
import Values

private let logger = BudLogger("ActionSourceMock")


// MARK: Object
@Server
package final class ActionSourceMock: ActionSourceInterface {
    // MARK: core
    init(name: String,
         owner: ObjectSourceMock.ID) {
        self.name = name
        self.owner = owner
        
        ActionSourceMockManager.register(self)
    }
    func delete() {
        ActionSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let owner: ObjectSourceMock.ID
    nonisolated let target = ActionID()
    
    var name: String
    package func setName(_ value: String) async {
        self.name = value
    }
    
    var handlers: [ObjectID: EventHandler] = [:]
    package func setHandler(requester: ObjectID, _ handler: Handler<ActionSourceEvent>) async {
        self.handlers[requester] = handler
    }

    
    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // compute
        let diff = ActionSourceDiff(self)
        self.handlers.values
            .forEach { $0.execute(.modified(diff)) }
    }

    package func duplicateAction() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSource가 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSourceRef = self.owner.ref!
        let index = objectSourceRef.actions.index(forKey: self.target)!
        let newIndex = index.advanced(by: 1)
        
        // mutate
        let newActionSourceRef = ActionSourceMock(
            name: self.name,
            owner: self.owner)
        objectSourceRef.actions.updateValue(
            newActionSourceRef.id,
            forKey: newActionSourceRef.target,
            insertingAt: newIndex)
        
        // notify
        let diff = ActionSourceDiff(newActionSourceRef)
        
        self.handlers.values
            .forEach { $0.execute(.actionDuplicated(diff))}
    }
    package func removeAction() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("ActionSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSourceRef = self.owner.ref!
        
        // mutate
        objectSourceRef.actions[self.target] = nil
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
    }
    
    
    // MARK: value
    @Server
    package struct ID: ActionSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            ActionSourceMockManager.container[self] != nil
        }
        package var ref: ActionSourceMock? {
            ActionSourceMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<ActionSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class ActionSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [ActionSourceMock.ID: ActionSourceMock] = [:]
    fileprivate static func register(_ object: ActionSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: ActionSourceMock.ID) {
        container[id] = nil
    }
}

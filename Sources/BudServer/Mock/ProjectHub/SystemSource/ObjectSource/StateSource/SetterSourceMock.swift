//
//  SetterSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/22/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("SetterSourceMock")


// MARK: Object
@Server
package final class SetterSourceMock: SetterSourceInterface {
    // MARK: core
    init(name: String, owner: StateSourceMock.ID) {
        self.name = name
        self.owner = owner
        
        SetterSourceMockManager.register(self)
    }
    func delete() {
        SetterSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target = SetterID()
    nonisolated let owner: StateSourceMock.ID
    
    var name: String
    package func setName(_ value: String) {
        self.name = value
    }
    
    var handlers: [ObjectID:EventHandler] = [:]
    package func appendHandler(requester: ObjectID, _ handler: Handler<SetterSourceEvent>) async {
        self.handlers[requester] = handler
    }
    
    
    var parameters: OrderedDictionary<ParameterValue, ValueID> = [:]
    package func setParameters(_ value: OrderedSet<ParameterValue>) {
        self.parameters = value.toDictionary()
    }
    
    package func setHandler(requester: ObjectID, _ handler: EventHandler) async {
        
        self.handlers[requester] = handler
    }
    
    package func setName(_ value: String) async {
        self.name = value
    }
    

    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSourceMock이 존재하지 않습니다.")
            return
        }
        
        // notify
        let diff = SetterSourceDiff(self)
        
        self.handlers.values
            .forEach { $0.execute(.modified(diff)) }
    }
    
    package func duplicateSetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSourceMock이 존재하지 않습니다.")
            return
        }
        let stateSourceRef = self.owner.ref!
        let index = stateSourceRef.setters.index(forKey: self.target)!
        
        // compute
        let newIndex = index.advanced(by: 1)
        
        // mutate
        let newSetterSourceRef = SetterSourceMock(name: self.name,
                                                  owner: self.owner)
        stateSourceRef.setters.updateValue(
            newSetterSourceRef.id,
            forKey: newSetterSourceRef.target,
            insertingAt: newIndex
        )
        
        // notify
        let diff = SetterSourceDiff(newSetterSourceRef)
        self.handlers.values
            .forEach { $0.execute(.setterDuplicated(diff))}
    }
    package func removeSetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("SetterSourceMock이 존재하지 않습니다.")
            return
        }
        let stateSourceRef = self.owner.ref!
        
        // mutate
        stateSourceRef.setters[self.target] = nil
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
    }

    
    
    // MARK: value
    @Server
    package struct ID: SetterSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            SetterSourceMockManager.container[self] != nil
        }
        package var ref: SetterSourceMock? {
            SetterSourceMockManager.container[self]
        }
    }
    package typealias EventHandler = Handler<SetterSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class SetterSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterSourceMock.ID: SetterSourceMock] = [:]
    fileprivate static func register(_ object: SetterSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterSourceMock.ID) {
        container[id] = nil
    }
}


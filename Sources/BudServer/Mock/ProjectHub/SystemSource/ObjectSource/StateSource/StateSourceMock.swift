//
//  StateSourceMock.swift
//  BudClient
//
//  Created by 김민우 on 7/21/25.
//
import Foundation
import Values
import Collections

private let logger = BudLogger("StateSourceMock")


// MARK: Object
@Server
package final class StateSourceMock: StateSourceInterface {
    // MARK: core
    init(name: String,
         accessLevel: AccessLevel = .readAndWrite,
         stateValue: StateValue? = nil,
         owner: ObjectSourceMock.ID) {
        self.owner = owner
        
        self.name = name
        self.accessLevel = accessLevel
        
        StateSourceMockManager.register(self)
    }
    func delete() {
        StateSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let owner: ObjectSourceMock.ID
    nonisolated let target = StateID()
    
    nonisolated let createdAt: Date = .now
    var updatedAt: Date = .now
    var order: Int = 0
    
    var handlers: [ObjectID:EventHandler] = [:]
    var name: String
    
    var accessLevel: AccessLevel
    var stateValue: StateValue?
    
    var syncQueue: Deque<ObjectID> = []
    
    var getters: OrderedDictionary<GetterID, GetterSourceMock.ID> = [:]
    var setters: OrderedDictionary<SetterID, SetterSourceMock.ID> = [:]
    
    package func registerSync(_ object: ObjectID) async {
        self.syncQueue.append(object)
    }
    
    package func appendHandler(requester: ObjectID, _ handler: Handler<StateSourceEvent>) async {
        
        self.handlers[requester] = handler
    }
    
    package func setName(_ value: String) async {
        self.name = value
    }
    package func setStateValue(_ value: StateValue?) async {
        self.stateValue = value
    }
    package func setAccessLevel(_ value: AccessLevel) async {
        self.accessLevel = value
    }
    
    

    // MARK: action
    package func notifyStateChanged() async {
        logger.start()
        
        let diff = StateSourceDiff(self)
        
        self.handlers.values
            .forEach { $0.execute(.modified(diff))}
    }
    package func synchronize() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("StateSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        while syncQueue.isEmpty == false {
            let object = syncQueue.removeFirst()
            
            getters.values
                .compactMap { $0.ref }
                .map { GetterSourceDiff($0) }
                .forEach {
                    self.handlers[object]?.execute(.getterAdded($0))
                }
            
            setters.values
                .compactMap { $0.ref }
                .map { SetterSourceDiff($0) }
                .forEach {
                    self.handlers[object]?.execute(.setterAdded($0))
                }
        }
    }
    
    package func appendNewGetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("StateSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        let getterSourceRef = GetterSourceMock(name: "New Getter", owner: self.id)
        self.getters[getterSourceRef.target]  = getterSourceRef.id
        
        // notify
        let diff = GetterSourceDiff(getterSourceRef)
        
        self.handlers.values.forEach { eventHandler in
            eventHandler.execute(.getterAdded(diff))
        }
    }
    package func appendNewSetter() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("StateSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        
        // mutate
        let setterSourceRef = SetterSourceMock(name: "New Setter", owner: self.id)
        self.setters[setterSourceRef.target] = setterSourceRef.id
        
        // notify
        let diff = SetterSourceDiff(setterSourceRef)
        
        self.handlers.values.forEach { eventHandler in
            eventHandler.execute(.setterAdded(diff))
        }
    }
    
    package func duplicateState() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("StateSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSourceRef = self.owner.ref!
        
        // mutate
        let newStateSourceRef = StateSourceMock(
            name: self.name,
            accessLevel: self.accessLevel,
            stateValue: self.stateValue,
            owner: self.owner
        )
        objectSourceRef.states[newStateSourceRef.target] = newStateSourceRef.id
        
        // notify
        let diff = StateSourceDiff(newStateSourceRef)
        
        self.handlers.values
            .forEach { $0.execute(.stateDuplicated(diff)) }
    }
    package func removeState() async {
        logger.start()
        
        // capture
        guard id.isExist else {
            logger.failure("StateSourceMock이 존재하지 않아 실행 취소됩니다.")
            return
        }
        let objectSourceRef = self.owner.ref!
        
        // mutate
        self.getters.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        self.setters.values
            .compactMap { $0.ref }
            .forEach { $0.delete() }
        
        objectSourceRef.states[self.target] = nil
        self.delete()
        
        // notify
        self.handlers.values
            .forEach { $0.execute(.removed) }
    }

    
    
    // MARK: value
    @Server
    package struct ID: StateSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            StateSourceMockManager.container[self] != nil
        }
        package var ref: StateSourceMock? {
            StateSourceMockManager.container[self]
        }
    }
    typealias EventHandler = Handler<StateSourceEvent>
}


// MARK: ObjectManager
@Server
fileprivate final class StateSourceMockManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateSourceMock.ID: StateSourceMock] = [:]
    fileprivate static func register(_ object: StateSourceMock) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateSourceMock.ID) {
        container[id] = nil
    }
}

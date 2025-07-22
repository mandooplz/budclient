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
    init(name: String) {
        self.name = name
        
        StateSourceMockManager.register(self)
    }
    func delete() {
        StateSourceMockManager.unregister(self.id)
    }
    
    
    // MARK: state
    package nonisolated let id = ID()
    nonisolated let target = StateID()
    
    var handlers: [ObjectID:EventHandler] = [:]
    var name: String
    var accessLevel: AccessLevel = .readAndWrite
    var stateValue: StateValue = .AnyValue
    
    var syncQueue: Deque<ObjectID> = []
    
    var getters: [GetterID: GetterSourceMock.ID] = [:]
    var setters: [SetterID: SetterSourceMock.ID] = [:]
    
    package func registerSync(_ object: ObjectID) async {
        self.syncQueue.append(object)
    }
    
    package func setHandler(requester: ObjectID, _ handler: Handler<StateSourceEvent>) async {
        
        self.handlers[requester] = handler
    }
    
    package func setName(_ value: String) async {
        self.name = value
    }
    package func setStateData(_ accessLevel: AccessLevel, _ stateValue: StateValue) async {
        self.accessLevel = accessLevel
        self.stateValue = stateValue
    }
    
    

    // MARK: action
    package func notifyStateChanged() async {
        let diff = StateSourceDiff(self)
        
        self.handlers.values
            .forEach {
                $0.execute(.modified(diff))
            }
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
        let getterSourceRef = GetterSourceMock(name: "New Getter")
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
        let setterSourceRef = SetterSourceMock(name: "New Setter")
        self.setters[setterSourceRef.target] = setterSourceRef.id
        
        // notify
        let diff = SetterSourceDiff(setterSourceRef)
        
        self.handlers.values.forEach { eventHandler in
            eventHandler.execute(.setterAdded(diff))
        }
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

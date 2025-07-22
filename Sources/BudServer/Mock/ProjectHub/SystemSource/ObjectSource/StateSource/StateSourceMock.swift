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
    
    var handlers: [ObjectID:EventHandler?] = [:]
    var name: String
    var accessLevel: AccessLevel = .readAndWrite
    var stateValue: StateValue = .AnyValue
    
    var getters: [GetterID: GetterSourceMock.ID] = [:]
    var setters: [SetterID: SetterSourceMock.ID] = [:]
    
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
                $0?.execute(.modified(diff))
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

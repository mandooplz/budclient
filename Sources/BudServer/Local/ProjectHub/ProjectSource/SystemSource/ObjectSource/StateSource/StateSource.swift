//
//  StateSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import FirebaseFirestore
import BudMacro
import BudServer


// MARK: Object
@MainActor
package final class StateSource: StateSourceInterface {
    // MARK: core
    
    // MARK: state
    nonisolated let id = ID()
    
    var handler: EventHandler?
    package func appendHandler(requester: ObjectID, _ handler: Handler<StateSourceEvent>) async {
        fatalError()
    }
    
    package func setName(_ value: String) async {
        fatalError()
    }
    package func setStateValue(_ value: StateValue) async {
        fatalError()
    }
    package func setAccessLevel(_ value: AccessLevel) async {
        fatalError()
    }
    
    package func registerSync(_ object: ObjectID) async {
        fatalError()
    }
    
    
    // MARK: action
    package func synchronize() async {
        fatalError()
    }
    package func notifyStateChanged() async {
        fatalError()
    }
    
    package func appendNewGetter() async {
        fatalError()
    }
    package func appendNewSetter() async {
        fatalError()
    }
    
    package func duplicateState() async {
        fatalError()
    }
    package func removeState() async {
        fatalError()
    }
    
    
    
    
    // MARK: value
    @MainActor
    package struct ID: StateSourceIdentity {
        let value = UUID()
        nonisolated init() { }
        
        package var isExist: Bool {
            StateSourceManager.container[self] != nil
        }
        package var ref: StateSource? {
            StateSourceManager.container[self]
        }
    }
    @ShowState
    package struct Data: Codable {
        @DocumentID var id: String?
        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
        var order: Int
        
        package var target: StateID
        
        package var name: String
        package var accessLevel: AccessLevel
        package var stateValue: Values.StateValue
        
        init(order: Int = 0, name: String,
             accessLevel: AccessLevel = .readAndWrite,
             stateValue: StateValue = .anyState) {
            self.order = order
            self.name = name
            self.target = StateID()
            self.accessLevel = accessLevel
            self.stateValue = stateValue
        }
    }
    typealias EventHandler = Handler<StateSourceEvent>
}


// MARK: ObjectManager
@MainActor
fileprivate final class StateSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [StateSource.ID: StateSource] = [:]
    fileprivate static func register(_ object: StateSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: StateSource.ID) {
        container[id] = nil
    }
}

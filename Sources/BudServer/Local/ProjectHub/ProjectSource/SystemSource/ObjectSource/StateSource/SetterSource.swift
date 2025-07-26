//
//  SetterSource.swift
//  BudClient
//
//  Created by 김민우 on 7/17/25.
//
import Foundation
import Values
import Collections
import BudMacro
import FirebaseFirestore

private let logger = BudLogger("SetterSource")


// MARK: Object
@MainActor
package final class SetterSource: SetterSourceInterface {
    // MARK: core
    init(id: ID, target: SetterID, owner: StateSource.ID) {
        self.id = id
        self.target = target
        self.owner = owner
        
        SetterSourceManager.register(self)
    }
    func delete() {
        SetterSourceManager.unregister(self.id)
    }
    
    
    // MARK: state
    nonisolated let id: ID
    nonisolated let target: SetterID
    nonisolated let owner: StateSource.ID
    
    
    // MARK: action
    package func setName(_ value: String) async {
        fatalError()
    }
    
    package func setParameters(_ value: OrderedCollections.OrderedSet<Values.ParameterValue>) async {
        fatalError()
    }
    
    package func appendHandler(requester: Values.ObjectID, _ handler: Values.Handler<SetterSourceEvent>) async {
        fatalError()
    }
    
    package func notifyStateChanged() async {
        fatalError()
    }
    
    package func duplicateSetter() async {
        fatalError()
    }
    
    package func removeSetter() async {
        fatalError()
    }
    
    // MARK: value
    @MainActor
    package struct ID: SetterSourceIdentity {
        let value: String
        nonisolated init(_ value: String) {
            self.value = value
        }
        
        package var isExist: Bool {
            SetterSourceManager.container[self] != nil
        }
        package var ref: SetterSource? {
            SetterSourceManager.container[self]
        }
    }
}


// MARK: ObjectManager
@MainActor
fileprivate final class SetterSourceManager: Sendable {
    // MARK: state
    fileprivate static var container: [SetterSource.ID: SetterSource] = [:]
    fileprivate static func register(_ object: SetterSource) {
        container[object.id] = object
    }
    fileprivate static func unregister(_ id: SetterSource.ID) {
        container[id] = nil
    }
}

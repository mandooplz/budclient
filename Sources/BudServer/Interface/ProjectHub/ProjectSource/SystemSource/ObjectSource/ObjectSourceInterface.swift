//
//  ObjectSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ObjectSourceInterface: Sendable {
    associatedtype ID: ObjectSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func setHandler(for requester: ObjectID,
                    _ handler: Handler<ObjectSourceEvent>) async
    
    func notifyNameChanged() async
    
    func synchronize(requester: ObjectID) async
    
    
    // MARK: action
    func appendNewState() async
    func appendNewAction() async
}


package protocol ObjectSourceIdentity: Sendable, Hashable {
    associatedtype Object: ObjectSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}


// MARK: Values
package enum ObjectSourceEvent: Sendable {
    case modified(ObjectSourceDiff)
    case removed
    
    case addedState(StateSourceDiff)
    case actionAdded(ActionSourceDiff)
}


public struct ObjectSourceDiff: Sendable {
    package let id: any ObjectSourceIdentity
    package let target: ObjectID
    
    package let name: String
    package let role: ObjectRole
    
    // MARK: core
    @Server
    init(_ object: ObjectSourceMock) {
        self.id = object.id
        self.target = object.target
        self.name = object.name
        self.role = object.role
    }
    
    init(id: any ObjectSourceIdentity,
         target: ObjectID,
         name: String,
         role: ObjectRole) {
        self.id = id
        self.target = target
        self.name = name
        self.role = role
    }
    
    
    // MARK: operator
    func newName(_ value: String) -> Self {
        .init(id: self.id, target: self.target, name: value, role: self.role)
    }
}





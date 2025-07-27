//
//  ObjectSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/11/25.
//
import Foundation
import Collections
import Values


// MARK: Interface
package protocol ObjectSourceInterface: Sendable, SyncInterface {
    associatedtype ID: ObjectSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func appendHandler(requester: ObjectID, _ handler: Handler<ObjectSourceEvent>) async
    
    
    
    // MARK: action
    func notifyStateChanged() async
    
    func createChildObject() async
    
    func appendNewState() async
    func appendNewAction() async
    
    func removeObject() async
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
    
    case stateAdded(StateSourceDiff)
    case actionAdded(ActionSourceDiff)
}


public struct ObjectSourceDiff: Sendable {
    package let id: any ObjectSourceIdentity
    package let target: ObjectID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let role: ObjectRole
    package let parent: ObjectID?
    package let childs: OrderedSet<ObjectID>
    
    // MARK: core
    @Server
    init(_ objectRef: ObjectSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updateAt
        self.order = objectRef.order
        
        self.name = objectRef.name
        self.role = objectRef.role
        self.parent = objectRef.parent
        self.childs = objectRef.childs
    }

    
    init(id: any ObjectSourceIdentity, target: ObjectID, createdAt: Date, updatedAt: Date, order: Int, name: String, role: ObjectRole, parent: ObjectID?, childs: OrderedSet<ObjectID>) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.role = role
        self.parent = parent
        self.childs = childs
    }
    
    // MARK: operator
    func newName(_ value: String) -> Self {
        .init(id: self.id,
              target: self.target,
              createdAt: self.createdAt,
              updatedAt: self.updatedAt,
              order: self.order,
              name: value,
              role: self.role,
              parent: self.parent,
              childs: self.childs)
    }
}





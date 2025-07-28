//
//  ActionSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import Values


// MARK: Interface
package protocol ActionSourceInterface: Sendable {
    associatedtype ID: ActionSourceIdentity where ID.Object == Self
    
    // MARK: state
    func setName(_ value: String) async
    func appendHandler(requester: ObjectID, _ handler: Handler<ActionSourceEvent>) async

    
    // MARK: action
    func notifyStateChanged() async
    
    func duplicateAction() async
    func removeAction() async
}


package protocol ActionSourceIdentity: Sendable, Hashable {
    associatedtype Object: ActionSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Value
package struct ActionSourceDiff: Sendable {
    package let id: any ActionSourceIdentity
    package let target: ActionID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    
    package init(id: any ActionSourceIdentity, target: ActionID, createdAt: Date, updatedAt: Date, order: Int, name: String) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
    }
    
    @Server
    internal init(_ objectRef: ActionSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
    }
}


package enum ActionSourceEvent: Sendable {
    case modified(ActionSourceDiff)
    case removed
}

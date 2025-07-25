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
    func setHandler(requester: ObjectID, _ handler: Handler<ActionSourceEvent>) async

    
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
    package let name: String
    
    @Server
    internal init(_ objectRef: ActionSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        self.name = objectRef.name
    }
}


package enum ActionSourceEvent: Sendable {
    case modified(ActionSourceDiff)
    case removed
    case actionDuplicated(ActionID, ActionSourceDiff)
}

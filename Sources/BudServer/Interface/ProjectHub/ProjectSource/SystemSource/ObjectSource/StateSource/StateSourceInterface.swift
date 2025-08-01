//
//  StateSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import Values
import Collections


// MARK: Interface
package protocol StateSourceInterface: Sendable, SyncInterface {
    associatedtype ID: StateSourceIdentity where ID.Object == Self
    
    
    // MARK: state
    func appendHandler(requester: ObjectID, _ handler: Handler<StateSourceEvent>) async;
    
    func setName(_ value: String) async;
    func setAccessLevel(_ value: AccessLevel) async;
    func setStateValue(_ value: StateValue?) async;
    
    
    // MARK: action
    func notifyStateChanged() async;
    
    func appendNewGetter() async;
    func appendNewSetter() async;
    
    func duplicateState() async;
    func removeState() async;
}


package protocol StateSourceIdentity: Sendable, Hashable {
    associatedtype Object: StateSourceInterface where Object.ID == Self
    
    var isExist: Bool { get async }
    var ref: Object? { get async }
}



// MARK: Value
package struct StateSourceDiff: Sendable {
    package let id: any StateSourceIdentity
    package let target: StateID
    
    package let createdAt: Date
    package let updatedAt: Date
    package let order: Int
    
    package let name: String
    package let accessLevel: AccessLevel
    package let stateValue: StateValue?
    
    package init(id: any StateSourceIdentity, target: StateID, createdAt: Date, updatedAt: Date, order: Int, name: String, accessLevel: AccessLevel, stateValue: StateValue?) {
        self.id = id
        self.target = target
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.name = name
        self.accessLevel = accessLevel
        self.stateValue = stateValue
    }
    
    @Server
    init(_ objectRef: StateSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
        
        self.createdAt = objectRef.createdAt
        self.updatedAt = objectRef.updatedAt
        self.order = objectRef.order
        
        self.name = objectRef.name
        self.accessLevel = objectRef.accessLevel
        self.stateValue = objectRef.stateValue
    }
}

package enum StateSourceEvent: Sendable {
    case modified(StateSourceDiff)
    case removed
    
    case getterAdded(GetterSourceDiff)
    case setterAdded(SetterSourceDiff)
}

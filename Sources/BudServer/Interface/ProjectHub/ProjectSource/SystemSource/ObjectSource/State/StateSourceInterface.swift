//
//  StateSourceInterface.swift
//  BudClient
//
//  Created by 김민우 on 7/19/25.
//
import Foundation
import Values


// MARK: Interface
package protocol StateSourceInterface: Sendable {
    associatedtype ID: StateSourceIdentity where ID.Object == Self
    
    // MARK: state

    
    // MARK: action
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
    package let name: String
    
    package let accessLevel: AccessLevel
    package let stateValue: StateValue
    
    @Server
    init(_ objectRef: StateSourceMock) {
        self.id = objectRef.id
        self.target = objectRef.target
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

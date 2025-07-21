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

    
    // MARK: action
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
